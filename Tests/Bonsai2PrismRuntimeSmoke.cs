using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Godot;

public partial class Bonsai2PrismRuntimeSmoke : Node
{
    [Export]
    public bool RunLive { get; set; }

    private static readonly DialogueMessage[] TestContext =
    {
        new("system", "Ты доброжелательный NPC. Отвечай по-русски."),
        new("user", "Посмотри на мой фургон и посоветуй, что проверить."),
    };

    public override async void _Ready()
    {
        try
        {
            await RetriesEmptyAnswersWithoutLeakingDrafts();
            await RetriesTransientHttpFailure();
            await RepairsAnUnfinishedSentence();
            await RetriesWithLargerBudgetAfterLengthFinish();
            await ShortensContextAfterRepeatedEmptyResponses();
            await ReportsEmptyResponseOnlyAfterRetries();
            GD.Print("PASS: Bonsai Prism deterministic recovery checks");

            if (RunLive || OS.GetCmdlineUserArgs().Contains("--live"))
                await RunLiveDialogue();

            GetTree().Quit();
        }
        catch (Exception exception)
        {
            GD.PrintErr(exception);
            GetTree().Quit(1);
        }
    }

    private static async Task RetriesEmptyAnswersWithoutLeakingDrafts()
    {
        using var handler = new ScriptedHandler(
            Sse("Готово."), Sse(null), Sse(""), Sse("Осмотрю фургон и проверю шины."));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        var delivered = new List<string>();
        string answer = await runtime.GenerateAsync(TestContext, onText: delivered.Add);

        Check(answer == "Осмотрю фургон и проверю шины.", "Empty responses were not retried to a valid answer.");
        Check(runtime.LastAttemptCount == 3, "Expected two empty-response retries.");
        Check(delivered.SequenceEqual(new[] { answer }), "An empty or rejected draft reached the UI callback.");
        using JsonDocument retryRequest = JsonDocument.Parse(handler.ChatRequests[2]);
        JsonElement retry = retryRequest.RootElement;
        string recoveryPrompt = retry.GetProperty("messages")[retry.GetProperty("messages").GetArrayLength() - 1]
            .GetProperty("content").GetString();
        Check(recoveryPrompt.Contains("не выдала текста", StringComparison.OrdinalIgnoreCase),
            "Retry repeated the original prompt without explaining the empty completion.");
        Check(retry.GetProperty("temperature").GetSingle() >= 0.9f &&
            retry.GetProperty("top_p").GetSingle() >= 0.95f,
            "Retry did not adjust sampling after an empty completion.");
    }

    private static async Task RetriesTransientHttpFailure()
    {
        using var handler = new ScriptedHandler(
            Sse("Готово."),
            _ => new HttpResponseMessage(HttpStatusCode.ServiceUnavailable)
                { Content = new StringContent("temporary upstream error") },
            Sse("Сейчас посмотрю."));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        string answer = await runtime.GenerateAsync(TestContext);

        Check(answer == "Сейчас посмотрю." && runtime.LastAttemptCount == 2,
            "A transient HTTP 503 did not recover automatically.");
    }

    private static async Task RepairsAnUnfinishedSentence()
    {
        const string draft = "Понял, давайте я посмотрю на ваш фур";
        const string repaired = "Понял, давайте я посмотрю на ваш фургон.";
        using var handler = new ScriptedHandler(Sse("Готово."), Sse(draft), Sse(repaired));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        var delivered = new List<string>();
        string answer = await runtime.GenerateAsync(TestContext, onText: delivered.Add);

        Check(answer == repaired && runtime.LastAttemptCount == 2,
            "The unfinished sentence was not regenerated as a complete sentence.");
        Check(delivered.SequenceEqual(new[] { repaired }), "The unfinished draft was shown before repair.");
        using JsonDocument repairRequest = JsonDocument.Parse(handler.ChatRequests[2]);
        JsonElement messages = repairRequest.RootElement.GetProperty("messages");
        Check(messages.GetArrayLength() == TestContext.Length + 2,
            "Repair request did not include the draft and correction instruction.");
        Check(messages[messages.GetArrayLength() - 2].GetProperty("content").GetString() == draft,
            "Repair request did not preserve the unfinished draft.");
    }

    private static async Task RetriesWithLargerBudgetAfterLengthFinish()
    {
        using var handler = new ScriptedHandler(
            Sse("Готово."), Sse("Начало ответа", "length"), Sse("Полный ответ с завершённой мыслью."));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        string answer = await runtime.GenerateAsync(TestContext);

        using JsonDocument retryRequest = JsonDocument.Parse(handler.ChatRequests[2]);
        Check(answer == "Полный ответ с завершённой мыслью." && runtime.LastAttemptCount == 2,
            "A length-limited response was not regenerated.");
        Check(retryRequest.RootElement.GetProperty("max_tokens").GetInt32() == 512,
            "Token budget was not increased after finish_reason=length.");
    }

    private static async Task ReportsEmptyResponseOnlyAfterRetries()
    {
        using var handler = new ScriptedHandler(
            Sse("Готово."), Sse(null), Sse(null), Sse(null), Sse(null));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        var delivered = new List<string>();
        bool failedAsEmpty = false;
        try
        {
            await runtime.GenerateAsync(TestContext, onText: delivered.Add);
        }
        catch (LocalLlmRuntimeException failure)
        {
            failedAsEmpty = failure.Kind == LocalLlmFailureKind.EmptyResponse;
        }

        Check(failedAsEmpty && runtime.LastAttemptCount == 4,
            "Four empty generations did not produce a clear final failure.");
        Check(delivered.Count == 0, "A failed generation emitted partial text.");
    }

    private static async Task ShortensContextAfterRepeatedEmptyResponses()
    {
        var context = new[]
        {
            new DialogueMessage("system", "Ты механик, отвечай по-русски."),
            new DialogueMessage("user", "Я приехал на фургоне."),
            new DialogueMessage("assistant", "Понял, что случилось?"),
            new DialogueMessage("user", "На панели загорелась лампа."),
            new DialogueMessage("assistant", "Нужно выяснить, какая именно."),
            new DialogueMessage("user", "Что проверить в первую очередь?"),
        };
        using var handler = new ScriptedHandler(
            Sse("Готово."), Sse(null), Sse(null), Sse(null), Sse("Сначала проверь уровень масла."));
        using var client = new System.Net.Http.HttpClient(handler);
        using var runtime = new Bonsai2PrismRuntime(TestConfig(), client);
        await runtime.PrepareAsync();

        string answer = await runtime.GenerateAsync(context);

        Check(answer == "Сначала проверь уровень масла." && runtime.LastAttemptCount == 4,
            "The compact-context recovery attempt did not produce an answer.");
        Check(runtime.LastRetryReason == "empty response", "The live retry reason was not retained.");
        using JsonDocument compactRequest = JsonDocument.Parse(handler.ChatRequests[4]);
        JsonElement messages = compactRequest.RootElement.GetProperty("messages");
        Check(messages.GetArrayLength() == 4,
            "The last recovery attempt did not keep system instructions and only the latest turn pair.");
        Check(messages[1].GetProperty("content").GetString() == "На панели загорелась лампа.",
            "The compact context did not preserve the most recent dialogue pair.");
        Check(messages[3].GetProperty("content").GetString().Contains("Предыдущие попытки не выдали текста"),
            "The compact recovery request did not tell the model that earlier outputs were empty.");
    }

    private async Task RunLiveDialogue()
    {
        var mainScene = GD.Load<PackedScene>("res://Main.tscn").Instantiate<Main>();
        var responder = mainScene.GetNode<LocalLlmResponder>("ChatResponder");
        var config = responder.Config.Duplicate(true) as LocalLlmConfig
            ?? throw new InvalidOperationException("Could not duplicate LocalLlmConfig.tres.");
        var runtime = new Bonsai2PrismRuntime(config);
        responder.Configure(runtime, responder.Profile
            ?? throw new InvalidOperationException("Main.tscn has no NpcProfile assigned."));

        var ready = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        void OnReady() => ready.TrySetResult();
        void OnPreparationFailed(string error) => ready.TrySetException(new InvalidOperationException(error));
        responder.PreparationFinished += OnReady;
        responder.ResponseFailed += OnPreparationFailed;
        AddChild(mainScene);
        await ready.Task.WaitAsync(TimeSpan.FromMinutes(16));
        responder.PreparationFinished -= OnReady;
        responder.ResponseFailed -= OnPreparationFailed;

        var input = mainScene.GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
        var sendButton = mainScene.GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
        var responseText = mainScene.GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        string[] questions =
        {
            "Привет! Расскажи, чем ты сейчас занят?",
            "Меня зовут Дмитрий, я приехал на фургоне.",
            "Как меня зовут и на чём я приехал?",
            "Пожалуйста, внимательно осмотри мой фургон и скажи, что проверить перед поездкой.",
            "С чего лучше начать проверку?",
            "А если на колесе мало воздуха?",
            "Повтори, что ты посоветовал насчёт колёс.",
            "Спасибо. Что ещё важно проверить?",
            "Можешь коротко подвести итог?",
            "И напомни, как меня зовут?",
            "Посмотри на мой фургон ещё раз: что бы ты проверил первым?",
            "Спасибо, этого достаточно."
        };

        GD.Print($"LIVE_BONSAI_START model={runtime.ModelId} turns={questions.Length}");
        for (int index = 0; index < questions.Length; index++)
        {
            string question = questions[index];
            var result = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnResponse(string answer) => result.TrySetResult(answer);
            void OnFailure(string error) => result.TrySetException(new InvalidOperationException(error));
            responder.ResponseReceived += OnResponse;
            responder.ResponseFailed += OnFailure;
            input.Text = question;
            sendButton.EmitSignal(Button.SignalName.Pressed);

            string answer;
            try
            {
                answer = await result.Task.WaitAsync(TimeSpan.FromSeconds(Math.Max(180, config.TimeoutSeconds * 4)));
            }
            finally
            {
                responder.ResponseReceived -= OnResponse;
                responder.ResponseFailed -= OnFailure;
            }

            Check(input.Text.Length == 0 && responseText.Text == answer,
                $"UI did not commit Bonsai turn {index + 1} correctly.");
            Check(!string.IsNullOrWhiteSpace(answer), $"Bonsai turn {index + 1} was empty.");
            GD.Print($"LIVE_BONSAI_TURN turn={index + 1} attempts={runtime.LastAttemptCount} " +
                $"finish_reason={runtime.LastFinishReason ?? "unknown"} " +
                $"retry={runtime.LastRetryReason ?? "none"} chars={answer.Length}");
            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        }

        Check(responder.History.MessageCount >= 2 &&
            responder.History.MessageCount <= config.MaxHistoryMessages &&
            responder.History.MessageCount % 2 == 0,
            "Live dialogue history exceeded its configured bound or has an unmatched turn.");
        Check(responder.Memory.PlayerName == "Дмитрий", "Live dialogue lost the player's remembered name.");
        GD.Print("PASS: Bonsai live dialogue UI burn-in");
        mainScene.QueueFree();
    }

    private static LocalLlmConfig TestConfig() => new()
    {
        Provider = LocalLlmProvider.Prism,
        BaseUrl = Bonsai2PrismRuntime.BaseUrl,
        EndpointPath = "/v1/chat/completions",
        ModelName = "bonsai-test",
        TimeoutSeconds = 5,
        MaxTokens = 256,
    };

    private static Func<HttpRequestMessage, HttpResponseMessage> Sse(string content, string finishReason = "stop")
    {
        return _ =>
        {
            var choice = new Dictionary<string, object>
            {
                ["delta"] = content == null ? new Dictionary<string, object>() : new { content },
                ["finish_reason"] = finishReason,
            };
            string eventJson = JsonSerializer.Serialize(new { choices = new[] { choice } });
            string body = $"data: {eventJson}\n\ndata: [DONE]\n\n";
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(body, Encoding.UTF8, "text/event-stream"),
            };
        };
    }

    private static void Check(bool condition, string message)
    {
        if (!condition) throw new InvalidOperationException(message);
    }

    private sealed class ScriptedHandler : HttpMessageHandler
    {
        private readonly Queue<Func<HttpRequestMessage, HttpResponseMessage>> _responses;

        public ScriptedHandler(params Func<HttpRequestMessage, HttpResponseMessage>[] chatResponses)
        {
            _responses = new Queue<Func<HttpRequestMessage, HttpResponseMessage>>(chatResponses);
        }

        public List<string> ChatRequests { get; } = new();

        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token)
        {
            string path = request.RequestUri?.AbsolutePath ?? string.Empty;
            if (request.Method == HttpMethod.Get && path == "/health")
                return new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent("ok") };
            if (request.Method == HttpMethod.Get && path == "/v1/models")
            {
                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent("{\"data\":[{\"id\":\"bonsai-test\"}]}", Encoding.UTF8, "application/json"),
                };
            }
            if (request.Method == HttpMethod.Post && path == "/v1/chat/completions")
            {
                ChatRequests.Add(await request.Content.ReadAsStringAsync(token));
                if (_responses.Count == 0)
                    throw new InvalidOperationException("Unexpected extra chat request in scripted test.");
                return _responses.Dequeue()(request);
            }
            throw new InvalidOperationException($"Unexpected HTTP request: {request.Method} {path}");
        }
    }
}
