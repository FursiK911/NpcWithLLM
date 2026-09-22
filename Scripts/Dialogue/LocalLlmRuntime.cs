using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using NetHttpClient = System.Net.Http.HttpClient;

public sealed class LocalLlmRuntime : ILocalLlmRuntime
{
    private static readonly NetHttpClient SharedClient = new() { Timeout = Timeout.InfiniteTimeSpan };
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
    private readonly LocalLlmConfig _config;
    private readonly NetHttpClient _http;

    public LocalLlmRuntime(LocalLlmConfig config, NetHttpClient http = null)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
        _http = http ?? SharedClient;
    }

    public async Task PrepareAsync(CancellationToken cancellationToken = default)
    {
        // A real short generation loads weights and initializes the same context budget as dialogue.
        await GenerateAsync(new[] { new DialogueMessage("user", "Ответь одним словом: готов.") },
            cancellationToken, null);
    }

    public async Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context,
        CancellationToken cancellationToken = default, Action<string> onText = null)
    {
        Uri endpoint = null;
        var stopwatch = Stopwatch.StartNew();
        try
        {
            try { endpoint = _config.GetEndpointUri(); }
            catch (ArgumentException exception)
            {
                throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.Configuration, exception.Message);
            }
            var payload = LocalLlmRequestBuilder.Create(_config.ModelName, context,
                _config.Temperature, _config.TopP, _config.MaxTokens, think: false, stream: true,
                contextTokens: _config.ContextTokens, presencePenalty: _config.PresencePenalty);
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(TimeSpan.FromSeconds(_config.TimeoutSeconds));
            using var request = new HttpRequestMessage(HttpMethod.Post, endpoint)
            {
                Content = new StringContent(JsonSerializer.Serialize(payload, JsonOptions), Encoding.UTF8, "application/json"),
            };
            using var response = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
            if (!response.IsSuccessStatusCode)
                throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.HttpError, $"HTTP {(int)response.StatusCode}");

            using var stream = await response.Content.ReadAsStreamAsync(timeout.Token);
            using var reader = new StreamReader(stream, Encoding.UTF8);
            var result = new StringBuilder();
            bool firstText = true;
            while (await reader.ReadLineAsync(timeout.Token) is string line)
            {
                if (string.IsNullOrWhiteSpace(line)) continue;
                using var document = JsonDocument.Parse(line);
                var root = document.RootElement;
                if (root.ValueKind != JsonValueKind.Object)
                    throw new JsonException("Expected a stream object.");
                if (root.TryGetProperty("error", out _))
                    throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.HttpError, "Ollama stream error.");
                if (!root.TryGetProperty("done", out var done) ||
                    (done.ValueKind != JsonValueKind.True && done.ValueKind != JsonValueKind.False))
                    throw new JsonException("Missing stream completion flag.");
                if (root.TryGetProperty("message", out var message))
                {
                    if (message.ValueKind != JsonValueKind.Object ||
                        !message.TryGetProperty("content", out var content) || content.ValueKind != JsonValueKind.String)
                        throw new JsonException("Missing message.content.");
                    string text = content.GetString();
                    if (!string.IsNullOrEmpty(text))
                    {
                        result.Append(text);
                        if (firstText && !string.IsNullOrWhiteSpace(result.ToString()))
                        {
                            GD.Print($"LocalLlmRuntime first text: {stopwatch.ElapsedMilliseconds} ms.");
                            firstText = false;
                        }
                        onText?.Invoke(text);
                    }
                }
                if (done.GetBoolean())
                {
                    if (root.TryGetProperty("done_reason", out var reason) && reason.GetString() == "length")
                        throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.IncompleteResponse, "Generation token limit reached.");
                    if (string.IsNullOrWhiteSpace(result.ToString()))
                        throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.EmptyResponse, "No visible content.");
                    return result.ToString().Trim();
                }
            }
            throw LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.IncompleteResponse, "Stream ended without done=true.");
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested) { throw; }
        catch (Exception exception)
        {
            var failure = exception as LocalLlmRuntimeException ?? exception switch
            {
                OperationCanceledException => LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.Timeout, "Request timed out."),
                HttpRequestException or IOException => LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.NetworkError, "Connection interrupted."),
                JsonException => LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.InvalidJson, "Invalid stream JSON."),
                _ => LocalLlmRuntimeException.CreateForKind(LocalLlmFailureKind.Unknown, exception.GetType().Name),
            };
            // Do not log response bodies: they can contain player dialogue or internal instructions.
            GD.PrintErr($"LocalLlmRuntime failure: kind={failure.Kind}; endpoint={endpoint}; details={failure.TechnicalDetails}");
            throw failure;
        }
        finally { GD.Print($"LocalLlmRuntime completed in {stopwatch.ElapsedMilliseconds} ms."); }
    }
}
