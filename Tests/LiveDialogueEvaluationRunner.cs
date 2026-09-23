using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Godot;

public partial class LiveDialogueEvaluationRunner : Node
{
    private const string EvalDirectory = @"D:\NpcWithLLM-GemmaEval-20260923";
    private const string CommandPath = EvalDirectory + @"\command.json";
    private const string ResultPath = EvalDirectory + @"\result.json";
    private const string StatusPath = EvalDirectory + @"\status.json";
    private const string DialoguePath = EvalDirectory + @"\dialogue.jsonl";
    private const string ModelName = "gemma4-12b-it-q2k-eval";

    public override void _Ready() => _ = RunAsync();

    private async Task RunAsync()
    {
        try
        {
            Directory.CreateDirectory(EvalDirectory);
            if (File.Exists(CommandPath)) File.Delete(CommandPath);
            if (File.Exists(ResultPath)) File.Delete(ResultPath);
            if (File.Exists(DialoguePath)) File.Delete(DialoguePath);

            var main = GD.Load<PackedScene>("res://Main.tscn").Instantiate<Main>();
            var responder = main.GetNode<LocalLlmResponder>("ChatResponder");
            var evalConfig = responder.Config.Duplicate(true) as LocalLlmConfig
                ?? throw new InvalidOperationException("Could not duplicate LocalLlmConfig.tres.");
            evalConfig.Provider = LocalLlmProvider.Ollama;
            evalConfig.BaseUrl = "http://127.0.0.1:11434";
            evalConfig.EndpointPath = "/api/chat";
            evalConfig.ModelName = ModelName;
            responder.Config = evalConfig;

            var prepared = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnPrepared() => prepared.TrySetResult();
            void OnPreparationFailed(string error) => prepared.TrySetException(new InvalidOperationException(error));
            responder.PreparationFinished += OnPrepared;
            responder.ResponseFailed += OnPreparationFailed;

            var preparationTimer = Stopwatch.StartNew();
            AddChild(main);
            await prepared.Task.WaitAsync(TimeSpan.FromMinutes(15));
            preparationTimer.Stop();
            responder.PreparationFinished -= OnPrepared;
            responder.ResponseFailed -= OnPreparationFailed;

            WriteJson(StatusPath, new
            {
                phase = "ready",
                model = ModelName,
                warmupMs = preparationTimer.Elapsed.TotalMilliseconds,
                profile = responder.Profile?.Name,
                temperature = evalConfig.Temperature,
                topP = evalConfig.TopP,
                numPredict = evalConfig.MaxTokens,
                numCtx = evalConfig.ContextTokens,
                presencePenalty = evalConfig.PresencePenalty,
                maxHistoryMessages = evalConfig.MaxHistoryMessages,
                maxHistoryCharacters = evalConfig.MaxHistoryCharacters,
            });
            GD.Print($"LIVE_EVAL_READY model={ModelName} warmupMs={preparationTimer.Elapsed.TotalMilliseconds:F1}");

            var input = main.GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
            var sendButton = main.GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
            var responseText = main.GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");

            for (int expectedTurn = 1; expectedTurn <= 32; expectedTurn++)
            {
                while (!File.Exists(CommandPath))
                    await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

                string commandJson = File.ReadAllText(CommandPath);
                File.Delete(CommandPath);
                using JsonDocument commandDocument = JsonDocument.Parse(commandJson);
                JsonElement command = commandDocument.RootElement;
                int turn = command.GetProperty("turn").GetInt32();
                string playerMessage = command.GetProperty("text").GetString() ?? string.Empty;
                if (turn != expectedTurn)
                    throw new InvalidOperationException($"Expected turn {expectedTurn}, received {turn}.");
                if (string.IsNullOrWhiteSpace(playerMessage))
                    throw new InvalidOperationException($"Turn {turn} was empty.");

                var timer = Stopwatch.StartNew();
                double firstTextMs = -1;
                var completed = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                void OnChunk(string text)
                {
                    if (firstTextMs < 0 && !string.IsNullOrWhiteSpace(text))
                        firstTextMs = timer.Elapsed.TotalMilliseconds;
                }
                void OnResponse(string response) => completed.TrySetResult(response);
                void OnFailure(string error) => completed.TrySetException(new InvalidOperationException(error));
                responder.ResponseChunkReceived += OnChunk;
                responder.ResponseReceived += OnResponse;
                responder.ResponseFailed += OnFailure;

                input.Text = playerMessage;
                sendButton.EmitSignal(Button.SignalName.Pressed);
                string answer;
                try
                {
                    answer = await completed.Task.WaitAsync(TimeSpan.FromSeconds(180));
                }
                finally
                {
                    responder.ResponseChunkReceived -= OnChunk;
                    responder.ResponseReceived -= OnResponse;
                    responder.ResponseFailed -= OnFailure;
                }
                timer.Stop();

                if (responseText.Text != answer || input.Text != string.Empty)
                    throw new InvalidOperationException($"UI did not finish turn {turn} correctly.");
                if (responder.History.MessageCount < 2 ||
                    responder.History.MessageCount > evalConfig.MaxHistoryMessages ||
                    responder.History.MessageCount % 2 != 0 ||
                    responder.History.CharacterCount > evalConfig.MaxHistoryCharacters)
                {
                    throw new InvalidOperationException(
                        $"Unexpected history size at turn {turn}: " +
                        $"{responder.History.MessageCount} messages, " +
                        $"{responder.History.CharacterCount} characters.");
                }

                var turnResult = new
                {
                    turn,
                    player = playerMessage,
                    character = answer,
                    firstTextMs = firstTextMs < 0 ? (double?)null : firstTextMs,
                    totalMs = timer.Elapsed.TotalMilliseconds,
                    historyMessages = responder.History.MessageCount,
                    historyCharacters = responder.History.CharacterCount,
                    memoryName = responder.Memory.PlayerName,
                    memoryProfession = responder.Memory.PlayerProfession,
                };
                File.AppendAllText(DialoguePath, JsonSerializer.Serialize(turnResult) + System.Environment.NewLine);
                WriteJson(ResultPath, turnResult);
                GD.Print($"LIVE_EVAL_TURN turn={turn} firstTextMs={firstTextMs:F1} totalMs={timer.Elapsed.TotalMilliseconds:F1}");
            }

            WriteJson(StatusPath, new
            {
                phase = "finished",
                model = ModelName,
                turns = 32,
                historyMessages = responder.History.MessageCount,
                historyCharacters = responder.History.CharacterCount,
                memoryName = responder.Memory.PlayerName,
                memoryProfession = responder.Memory.PlayerProfession,
            });
            GD.Print("LIVE_EVAL_FINISHED turns=32");
            main.QueueFree();
            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
            GetTree().Quit();
        }
        catch (Exception exception)
        {
            try { WriteJson(StatusPath, new { phase = "failed", error = exception.ToString() }); }
            catch { }
            GD.PrintErr(exception);
            GetTree().Quit(1);
        }
    }

    private static void WriteJson(string path, object value)
    {
        string temporaryPath = path + ".tmp";
        File.WriteAllText(temporaryPath, JsonSerializer.Serialize(value));
        File.Move(temporaryPath, path, true);
    }
}
