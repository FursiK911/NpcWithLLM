using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

/// <summary>
/// Runtime for the local Bonsai 2 model served by PrismML llama-server.
/// It extracts only OpenAI chat delta.content and deliberately ignores reasoning_content.
/// Each attempt is buffered until accepted so retries never expose an empty or partial draft.
/// </summary>
public sealed class Bonsai2PrismRuntime : ILocalLlmRuntime, IDisposable
{
    public const string BaseUrl = "http://127.0.0.1:8080";
    public const string RuntimeRelease = "prism-b10709-9a9394a";
    private static readonly TimeSpan ServerReadyTimeout = TimeSpan.FromSeconds(45);
    private const int MaxGenerationAttempts = 4;
    private const int MaxGenerationTokens = 1024;

    private static readonly HttpClient SharedClient = new() { Timeout = Timeout.InfiniteTimeSpan };
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    private readonly LocalLlmConfig _config;
    private readonly HttpClient _http;
    private readonly Uri _healthUri;
    private readonly Uri _modelsUri;
    private readonly Uri _chatUri;
    private string _modelId;
    private bool _prepared;

    public bool LastResponseContainedReasoningTags { get; private set; }
    public int LastAttemptCount { get; private set; }
    public string LastFinishReason { get; private set; }
    public string LastRetryReason { get; private set; }

    public Bonsai2PrismRuntime(LocalLlmConfig config, HttpClient http = null)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _http = http ?? SharedClient;
        _chatUri = _config.GetEndpointUri();
        string serviceRoot = _chatUri.GetLeftPart(UriPartial.Authority);
        _healthUri = new Uri($"{serviceRoot}/health");
        _modelsUri = new Uri($"{serviceRoot}/v1/models");
    }

    public string ModelId => _modelId;

    public async Task PrepareAsync(CancellationToken cancellationToken = default)
    {
        if (_prepared) return;

        using var startupTimeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        startupTimeout.CancelAfter(ServerReadyTimeout);
        var startupTimer = System.Diagnostics.Stopwatch.StartNew();
        bool healthy = false;
        while (!startupTimeout.IsCancellationRequested)
        {
            using var probeTimeout = CancellationTokenSource.CreateLinkedTokenSource(startupTimeout.Token);
            probeTimeout.CancelAfter(TimeSpan.FromSeconds(5));
            try
            {
                using var response = await _http.GetAsync(_healthUri, probeTimeout.Token);
                healthy = response.IsSuccessStatusCode;
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
            catch (OperationCanceledException) { }
            catch (HttpRequestException) { }

            if (healthy) break;
            if (startupTimeout.IsCancellationRequested) break;
            await Task.Delay(1000, startupTimeout.Token);
        }
        if (!healthy)
        {
            cancellationToken.ThrowIfCancellationRequested();
            throw LocalLlmRuntimeException.CreateForKind(
                LocalLlmFailureKind.PrismServerUnavailable,
                $"PrismML llama-server не ответил за {ServerReadyTimeout.TotalSeconds:0} секунд на {_healthUri}.");
        }

        _modelId = await ResolveModelIdAsync(startupTimeout.Token);

        // Match the game's preparation flow: issue a tiny local generation before the first dialogue turn.
        await GenerateWithRecoveryAsync(
            new[] { new DialogueMessage("user", "Ответь одним словом: готов.") },
            startupTimeout.Token,
            null,
            maxTokensOverride: 8,
            validateCompletion: false);
        _prepared = true;
    }

    public Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context,
        CancellationToken cancellationToken = default, Action<string> onText = null)
    {
        return GenerateWithRecoveryAsync(context, cancellationToken, onText,
            maxTokensOverride: null, validateCompletion: true);
    }

    private async Task<string> ResolveModelIdAsync(CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, _modelsUri);
        using var response = await _http.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException(
                $"PrismML /v1/models returned HTTP {(int)response.StatusCode}.",
                null,
                response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
        if (!document.RootElement.TryGetProperty("data", out var data) ||
            data.ValueKind != JsonValueKind.Array || data.GetArrayLength() == 0 ||
            !data[0].TryGetProperty("id", out var id) || id.ValueKind != JsonValueKind.String ||
            string.IsNullOrWhiteSpace(id.GetString()))
        {
            throw new InvalidDataException("PrismML /v1/models returned no model identifier.");
        }

        return id.GetString();
    }

    private async Task<string> GenerateWithRecoveryAsync(IReadOnlyList<DialogueMessage> context,
        CancellationToken cancellationToken, Action<string> onText, int? maxTokensOverride,
        bool validateCompletion)
    {
        if (context == null || context.Count == 0)
            throw new ArgumentException("Dialogue context is empty.", nameof(context));
        if (string.IsNullOrWhiteSpace(_modelId))
            throw new InvalidOperationException("PrismML model id has not been resolved yet.");

        IReadOnlyList<DialogueMessage> baseContext = validateCompletion
            ? AddCompletionGuard(context)
            : context;
        IReadOnlyList<DialogueMessage> attemptContext = baseContext;
        int maxTokens = maxTokensOverride ?? _config.MaxTokens;
        float temperature = _config.Temperature;
        float topP = _config.TopP;
        Exception lastFailure = null;
        LocalLlmFailureKind lastFailureKind = LocalLlmFailureKind.Unknown;
        bool sawReasoningTags = false;
        LastAttemptCount = 0;
        LastFinishReason = null;
        LastRetryReason = null;
        LastResponseContainedReasoningTags = false;

        for (int attempt = 1; attempt <= MaxGenerationAttempts; attempt++)
        {
            LastAttemptCount = attempt;
            try
            {
                GenerationResult result = await GenerateCoreAsync(
                    attemptContext, cancellationToken, maxTokens, temperature, topP);
                sawReasoningTags |= result.ContainedReasoningTags;
                LastFinishReason = result.FinishReason;

                if (string.IsNullOrWhiteSpace(result.Text))
                {
                    lastFailure = new InvalidDataException("PrismML completed the stream without visible assistant text.");
                    lastFailureKind = LocalLlmFailureKind.EmptyResponse;
                    LogRetry(attempt, "empty response", LastFinishReason, result.Text?.Length ?? 0);
                    attemptContext = attempt == 3
                        ? BuildMinimalEmptyRecoveryContext(baseContext)
                        : BuildEmptyRecoveryContext(baseContext);
                    temperature = Math.Min(1.0f, Math.Max(temperature + 0.15f, 0.9f));
                    topP = Math.Max(topP, 0.95f);
                    continue;
                }

                if (string.Equals(result.FinishReason, "length", StringComparison.OrdinalIgnoreCase))
                {
                    lastFailure = new IOException("PrismML reached the response token limit before completing the answer.");
                    lastFailureKind = LocalLlmFailureKind.IncompleteResponse;
                    LogRetry(attempt, "token limit", LastFinishReason, result.Text.Length);
                    maxTokens = Math.Min(MaxGenerationTokens, Math.Max(maxTokens + 1, maxTokens * 2));
                    attemptContext = baseContext;
                    continue;
                }

                if (validateCompletion && LooksLikelyTruncated(result.Text))
                {
                    lastFailure = new InvalidDataException("The answer ended without sentence-ending punctuation.");
                    lastFailureKind = LocalLlmFailureKind.IncompleteResponse;
                    LogRetry(attempt, "suspicious ending", LastFinishReason, result.Text.Length);
                    attemptContext = BuildRepairContext(baseContext, result.Text);
                    continue;
                }

                LastResponseContainedReasoningTags = sawReasoningTags;
                Console.WriteLine($"[Bonsai2PrismRuntime] completed attempts={attempt} " +
                    $"finish_reason={LastFinishReason ?? "unknown"} chars={result.Text.Length}.");
                onText?.Invoke(result.Text);
                return result.Text.Trim();
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception exception) when (IsRetryable(exception) && attempt < MaxGenerationAttempts)
            {
                lastFailure = exception;
                lastFailureKind = GetFailureKind(exception);
                LogRetry(attempt, exception.GetType().Name, LastFinishReason, 0);
            }
            catch (Exception exception)
            {
                LastResponseContainedReasoningTags = sawReasoningTags;
                Console.Error.WriteLine($"[Bonsai2PrismRuntime] failed attempt={attempt} " +
                    $"type={exception.GetType().Name} finish_reason={LastFinishReason ?? "unknown"}.");
                throw ToRuntimeException(exception);
            }
        }

        LastResponseContainedReasoningTags = sawReasoningTags;
        Console.Error.WriteLine($"[Bonsai2PrismRuntime] exhausted attempts={LastAttemptCount} " +
            $"failure={lastFailureKind} finish_reason={LastFinishReason ?? "unknown"}.");
        throw LocalLlmRuntimeException.CreateForKind(
            lastFailureKind,
            lastFailure?.Message ?? "PrismML did not produce a complete visible response.");
    }

    private async Task<GenerationResult> GenerateCoreAsync(IReadOnlyList<DialogueMessage> context,
        CancellationToken cancellationToken, int maxTokens, float temperature, float topP)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(TimeSpan.FromSeconds(_config.TimeoutSeconds));

        var payload = new Dictionary<string, object>
        {
            ["model"] = _modelId,
            ["messages"] = context.Select(message => new { role = message.Role, content = message.Content }).ToArray(),
            ["stream"] = true,
            ["temperature"] = temperature,
            ["top_p"] = topP,
            ["max_tokens"] = maxTokens,
            ["presence_penalty"] = _config.PresencePenalty,
            ["repeat_penalty"] = 1.0f,
            ["min_p"] = 0.0f,
            // Keep the OpenAI-compatible per-request override explicit. The evaluation server also
            // uses PrismML's forced --reasoning off mode to match the game's think:false setting.
            ["reasoning_effort"] = "none",
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, _chatUri)
        {
            Content = new StringContent(JsonSerializer.Serialize(payload, JsonOptions), Encoding.UTF8, "application/json"),
        };
        using var response = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
        if (!response.IsSuccessStatusCode)
            throw new HttpRequestException(
                $"PrismML chat completion returned HTTP {(int)response.StatusCode}.",
                null,
                response.StatusCode);

        using var stream = await response.Content.ReadAsStreamAsync(timeout.Token);
        using var reader = new StreamReader(stream, Encoding.UTF8);
        var visibleText = new StringBuilder();
        var reasoningTagFilter = new ReasoningTagFilter();
        bool completed = false;
        string finishReason = null;

        while (await reader.ReadLineAsync(timeout.Token) is string line)
        {
            if (!line.StartsWith("data:", StringComparison.Ordinal)) continue;
            string data = line[5..].TrimStart();
            if (data == "[DONE]")
            {
                completed = true;
                break;
            }

            using var document = JsonDocument.Parse(data);
            JsonElement root = document.RootElement;
            if (root.TryGetProperty("error", out JsonElement error))
                throw new HttpRequestException(error.ToString());
            if (!root.TryGetProperty("choices", out var choices) ||
                choices.ValueKind != JsonValueKind.Array || choices.GetArrayLength() == 0)
                continue;

            JsonElement choice = choices[0];
            if (choice.TryGetProperty("finish_reason", out JsonElement finishReasonElement) &&
                finishReasonElement.ValueKind == JsonValueKind.String)
            {
                finishReason = finishReasonElement.GetString();
            }
            if (!choice.TryGetProperty("delta", out var delta) || delta.ValueKind != JsonValueKind.Object)
                continue;

            // Deliberately read only visible assistant text. Do not inspect or persist reasoning_content.
            if (delta.TryGetProperty("content", out var content) && content.ValueKind == JsonValueKind.String)
            {
                string text = content.GetString();
                if (string.IsNullOrEmpty(text)) continue;
                string filteredText = reasoningTagFilter.Push(text);
                if (filteredText.Length == 0) continue;
                visibleText.Append(filteredText);
            }
        }

        string finalText = reasoningTagFilter.Push(string.Empty, flush: true);
        if (finalText.Length > 0)
            visibleText.Append(finalText);

        if (!completed)
            throw new IOException("PrismML SSE stream ended before the [DONE] event.");
        return new GenerationResult(visibleText.ToString().Trim(), finishReason,
            reasoningTagFilter.SawReasoningTag);
    }

    private static IReadOnlyList<DialogueMessage> AddCompletionGuard(IReadOnlyList<DialogueMessage> context)
    {
        var guarded = context.ToList();
        if (guarded[0].Role == "system")
        {
            guarded[0] = guarded[0] with
            {
                Content = guarded[0].Content +
                    "\nBefore ending, verify that the final word is complete and the last sentence is finished. " +
                    "Use terminal punctuation; never stop in the middle of a word or sentence.",
            };
        }
        return guarded;
    }

    private static IReadOnlyList<DialogueMessage> BuildRepairContext(
        IReadOnlyList<DialogueMessage> context, string draft)
    {
        var repair = context.ToList();
        repair.Add(new DialogueMessage("assistant", draft));
        repair.Add(new DialogueMessage("user",
            "Твоя предыдущая реплика, возможно, оборвалась. Перепиши её целиком: " +
            "закончи последнее слово и предложение, сохрани смысл и не добавляй новых фактов. " +
            "Верни только исправленную реплику."));
        return repair;
    }

    private static IReadOnlyList<DialogueMessage> BuildEmptyRecoveryContext(
        IReadOnlyList<DialogueMessage> context)
    {
        var recovery = context.ToList();
        int lastUserIndex = recovery.FindLastIndex(message => message.Role == "user");
        if (lastUserIndex < 0)
            throw new InvalidDataException("Dialogue context has no user message to recover from.");

        recovery[lastUserIndex] = recovery[lastUserIndex] with
        {
            Content = recovery[lastUserIndex].Content +
                "\n\nПредыдущая попытка не выдала текста. Ответь сейчас короткой полной репликой " +
                "по моему сообщению. Не оставляй ответ пустым; если не знаешь, скажи об этом одной фразой.",
        };
        return recovery;
    }

    private static IReadOnlyList<DialogueMessage> BuildMinimalEmptyRecoveryContext(
        IReadOnlyList<DialogueMessage> context)
    {
        int lastUserIndex = context.ToList().FindLastIndex(message => message.Role == "user");
        if (lastUserIndex < 0)
            throw new InvalidDataException("Dialogue context has no user message to recover from.");

        int firstSystemIndex = context.ToList().FindIndex(message => message.Role == "system");
        int firstKeptIndex = Math.Max(firstSystemIndex + 1, lastUserIndex - 2);
        while (firstKeptIndex < lastUserIndex && context[firstKeptIndex].Role != "user")
            firstKeptIndex++;

        var recovery = new List<DialogueMessage>();
        if (firstSystemIndex >= 0)
            recovery.Add(context[firstSystemIndex]);
        for (int index = firstKeptIndex; index <= lastUserIndex; index++)
            recovery.Add(context[index]);

        int recoveryUserIndex = recovery.FindLastIndex(message => message.Role == "user");
        recovery[recoveryUserIndex] = recovery[recoveryUserIndex] with
        {
            Content = recovery[recoveryUserIndex].Content +
                "\n\nПредыдущие попытки не выдали текста. Ответь сейчас коротким законченным " +
                "предложением по последнему сообщению. Не возвращай пустой ответ.",
        };
        return recovery;
    }

    private static bool LooksLikelyTruncated(string text)
    {
        string candidate = text.Trim();
        if (candidate.Length == 0) return false;

        candidate = candidate.TrimEnd('"', '\'', '»', '”', ')', ']', '}');
        if (candidate.Length == 0 || ".!?…".Contains(candidate[^1]))
            return false;

        int wordCount = candidate.Split((char[])null, StringSplitOptions.RemoveEmptyEntries).Length;
        return wordCount >= 6;
    }

    private static bool IsRetryable(Exception exception)
    {
        if (exception is IOException || exception is InvalidDataException || exception is JsonException)
            return true;
        if (exception is OperationCanceledException)
            return true;
        if (exception is not HttpRequestException httpException)
            return false;
        return !httpException.StatusCode.HasValue || (int)httpException.StatusCode.Value >= 500;
    }

    private static LocalLlmFailureKind GetFailureKind(Exception exception)
    {
        return exception switch
        {
            OperationCanceledException => LocalLlmFailureKind.Timeout,
            JsonException => LocalLlmFailureKind.InvalidJson,
            HttpRequestException httpException when httpException.StatusCode.HasValue => LocalLlmFailureKind.HttpError,
            HttpRequestException => LocalLlmFailureKind.NetworkError,
            IOException => LocalLlmFailureKind.IncompleteResponse,
            InvalidDataException => LocalLlmFailureKind.EmptyResponse,
            _ => LocalLlmFailureKind.Unknown,
        };
    }

    private static LocalLlmRuntimeException ToRuntimeException(Exception exception)
    {
        if (exception is LocalLlmRuntimeException runtimeException)
            return runtimeException;
        return LocalLlmRuntimeException.CreateForKind(GetFailureKind(exception), exception.Message);
    }

    private void LogRetry(int attempt, string reason, string finishReason, int characters)
    {
        LastRetryReason = reason;
        Console.Error.WriteLine($"[Bonsai2PrismRuntime] retry after attempt={attempt} reason={reason} " +
            $"finish_reason={finishReason ?? "unknown"} chars={characters}.");
    }

    private sealed record GenerationResult(string Text, string FinishReason, bool ContainedReasoningTags);

    // The runner owns the PrismML process separately; shutting down the transport must not kill it.
    public void Shutdown() { }

    public void Dispose() { }

    private sealed class ReasoningTagFilter
    {
        private const string StartTag = "<think>";
        private const string EndTag = "</think>";

        private readonly StringBuilder _pending = new();
        private bool _insideReasoning;

        public bool SawReasoningTag { get; private set; }

        public string Push(string text, bool flush = false)
        {
            if (!string.IsNullOrEmpty(text))
                _pending.Append(text);

            var visible = new StringBuilder();
            while (_pending.Length > 0)
            {
                string marker = _insideReasoning ? EndTag : StartTag;
                string buffered = _pending.ToString();
                int markerIndex = buffered.IndexOf(marker, StringComparison.Ordinal);
                if (markerIndex >= 0)
                {
                    if (!_insideReasoning && markerIndex > 0)
                        visible.Append(buffered, 0, markerIndex);

                    _pending.Remove(0, markerIndex + marker.Length);
                    _insideReasoning = !_insideReasoning;
                    SawReasoningTag = true;
                    continue;
                }

                if (flush)
                {
                    if (!_insideReasoning)
                        visible.Append(_pending);
                    _pending.Clear();
                    break;
                }

                int retainedSuffixLength = FindPartialMarkerSuffix(buffered, marker);
                int emitLength = _pending.Length - retainedSuffixLength;
                if (!_insideReasoning && emitLength > 0)
                    visible.Append(buffered, 0, emitLength);
                if (emitLength > 0)
                    _pending.Remove(0, emitLength);
                break;
            }

            return visible.ToString();
        }

        private static int FindPartialMarkerSuffix(string value, string marker)
        {
            for (int length = Math.Min(marker.Length - 1, value.Length); length > 0; length--)
            {
                if (value.EndsWith(marker[..length], StringComparison.Ordinal))
                    return length;
            }

            return 0;
        }
    }
}
