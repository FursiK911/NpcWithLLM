using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Godot;

public partial class Bonsai2LiveDialogueEvaluationRunner : Node
{
    private const string EvalDirectory = @"D:\NpcWithLLM-Bonsai2-Eval-20260923\run-13";
    private const string SeedDialoguePath = @"D:\NpcWithLLM-Bonsai2-Eval-20260923\run-11\dialogue.jsonl";
    private const string CommandPath = EvalDirectory + @"\command.json";
    private const string ResultPath = EvalDirectory + @"\result.json";
    private const string StatusPath = EvalDirectory + @"\status.json";
    private const string DialoguePath = EvalDirectory + @"\dialogue.jsonl";
    private const string ModelName = "Bonsai-2-27B-PTQ1_0";

    public override void _Ready() => _ = RunAsync();

    private async Task RunAsync()
    {
        try
        {
            Directory.CreateDirectory(EvalDirectory);
            foreach (string path in new[] { CommandPath, ResultPath, DialoguePath, StatusPath })
            {
                if (File.Exists(path))
                    throw new IOException($"Refusing to overwrite an existing evaluation file: {path}");
            }

            var main = GD.Load<PackedScene>("res://Main.tscn").Instantiate<Main>();
            var responder = main.GetNode<LocalLlmResponder>("ChatResponder");
            var evalConfig = responder.Config.Duplicate(true) as LocalLlmConfig
                ?? throw new InvalidOperationException("Could not duplicate LocalLlmConfig.tres.");
            responder.Config = evalConfig;
            var runtime = new Bonsai2PrismRuntime(evalConfig);
            responder.Configure(runtime, responder.Profile
                ?? throw new InvalidOperationException("Main.tscn has no NpcProfile assigned."));

            int resumedTurns = 0;
            if (File.Exists(SeedDialoguePath))
            {
                foreach (string line in File.ReadLines(SeedDialoguePath))
                {
                    using JsonDocument seedDocument = JsonDocument.Parse(line);
                    JsonElement seed = seedDocument.RootElement;
                    string player = seed.GetProperty("player").GetString() ?? string.Empty;
                    string character = seed.GetProperty("character").GetString() ?? string.Empty;
                    responder.Memory.LearnFrom(player);
                    responder.History.AddPair(player, character);
                    File.AppendAllText(DialoguePath, line + System.Environment.NewLine);
                    resumedTurns++;
                }
            }

            var prepared = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnPrepared() => prepared.TrySetResult();
            void OnPreparationFailed(string error) => prepared.TrySetException(new InvalidOperationException(error));
            responder.PreparationFinished += OnPrepared;
            responder.ResponseFailed += OnPreparationFailed;

            var preparationTimer = Stopwatch.StartNew();
            AddChild(main);
            await prepared.Task.WaitAsync(TimeSpan.FromMinutes(16));
            preparationTimer.Stop();
            responder.PreparationFinished -= OnPrepared;
            responder.ResponseFailed -= OnPreparationFailed;

            WriteJson(StatusPath, new
            {
                phase = "ready",
                model = ModelName,
                serverModelId = runtime.ModelId,
                runtime = Bonsai2PrismRuntime.RuntimeRelease,
                endpoint = Bonsai2PrismRuntime.BaseUrl,
                warmupMs = preparationTimer.Elapsed.TotalMilliseconds,
                profile = responder.Profile?.Name,
                temperature = evalConfig.Temperature,
                topP = evalConfig.TopP,
                numPredict = evalConfig.MaxTokens,
                numCtx = evalConfig.ContextTokens,
                presencePenalty = evalConfig.PresencePenalty,
                reasoningEffort = "none",
                serverReasoningMode = "off",
                maxHistoryMessages = evalConfig.MaxHistoryMessages,
                maxHistoryCharacters = evalConfig.MaxHistoryCharacters,
                resumedTurns,
            });
            GD.Print($"LIVE_EVAL_READY model={ModelName} resumedTurns={resumedTurns} " +
                $"warmupMs={preparationTimer.Elapsed.TotalMilliseconds:F1}");

            var input = main.GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
            var sendButton = main.GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
            var responseText = main.GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");

            for (int expectedTurn = resumedTurns + 1; expectedTurn <= 32; expectedTurn++)
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
                    reasoningTagsStripped = runtime.LastResponseContainedReasoningTags,
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
