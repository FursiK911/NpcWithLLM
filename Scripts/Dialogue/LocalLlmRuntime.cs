using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using Godot;
using NetHttpClient = System.Net.Http.HttpClient;

public sealed class LocalLlmRuntime : ILocalLlmRuntime
{
    private static readonly NetHttpClient HttpClient = new();
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };

    private readonly LocalLlmConfig _config;

    public LocalLlmRuntime(LocalLlmConfig config)
    {
        _config = config ?? throw new ArgumentNullException(nameof(config));
    }

    public async Task<string> GenerateAsync(
        IReadOnlyList<DialogueMessage> context,
        CancellationToken cancellationToken = default)
    {
        if (context == null || context.Count == 0)
        {
            throw LocalLlmRuntimeException.For(
                LocalLlmFailureKind.Configuration,
                "Контекст запроса пуст.");
        }

        Uri endpoint;
        try
        {
            endpoint = _config.GetEndpointUri();
        }
        catch (Exception exception) when (exception is ArgumentException || exception is UriFormatException)
        {
            LocalLlmRuntimeException failure = new(
                LocalLlmFailureKind.Configuration,
                "Неверно настроено подключение к локальной модели.",
                exception.Message,
                exception);
            LogFailure(endpoint: null, failure);
            throw failure;
        }

        Stopwatch stopwatch = Stopwatch.StartNew();
        try
        {
            OllamaChatRequest requestPayload = new(
                _config.ModelName.Trim(),
                context.Select(message => new OllamaMessage(message.Role, message.Content)).ToArray(),
                false,
                new OllamaOptions(_config.Temperature, _config.TopP, _config.MaxTokens));

            using HttpRequestMessage request = new(HttpMethod.Post, endpoint)
            {
                Content = new StringContent(
                    JsonSerializer.Serialize(requestPayload, JsonOptions),
                    Encoding.UTF8,
                    "application/json"),
            };

            using CancellationTokenSource timeoutSource = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeoutSource.CancelAfter(TimeSpan.FromSeconds(_config.TimeoutSeconds));

            HttpResponseMessage response;
            try
            {
                response = await HttpClient.SendAsync(
                    request,
                    HttpCompletionOption.ResponseContentRead,
                    timeoutSource.Token);
            }
            catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
            {
                throw CreateTimeoutFailure("during request", exception);
            }
            catch (HttpRequestException exception)
            {
                throw new LocalLlmRuntimeException(
                    LocalLlmFailureKind.NetworkError,
                    "Не удалось подключиться к локальной модели. Проверьте, запущен ли Ollama.",
                    exception.Message,
                    exception);
            }

            using (response)
            {
                if (!response.IsSuccessStatusCode)
                {
                    string status = $"HTTP {(int)response.StatusCode} {response.ReasonPhrase}".Trim();
                    throw new LocalLlmRuntimeException(
                        LocalLlmFailureKind.HttpError,
                        $"Сервис локальной модели вернул ошибку: {(int)response.StatusCode}.",
                        status);
                }

                string responseJson;
                try
                {
                    responseJson = await response.Content.ReadAsStringAsync(timeoutSource.Token);
                }
                catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
                {
                    throw CreateTimeoutFailure("while reading response", exception);
                }

                return ParseResponse(responseJson);
            }
        }
        catch (LocalLlmRuntimeException failure)
        {
            LogFailure(endpoint, failure);
            throw;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception)
        {
            LocalLlmRuntimeException failure = new(
                LocalLlmFailureKind.Unknown,
                "Не удалось получить ответ от локальной модели.",
                $"{exception.GetType().Name}: {exception.Message}",
                exception);
            LogFailure(endpoint, failure);
            throw failure;
        }
        finally
        {
            stopwatch.Stop();
            GD.Print($"LocalLlmRuntime request completed in {stopwatch.ElapsedMilliseconds} ms.");
        }
    }

    private static string ParseResponse(string responseJson)
    {
        if (string.IsNullOrWhiteSpace(responseJson))
        {
            throw LocalLlmRuntimeException.For(
                LocalLlmFailureKind.EmptyResponse,
                "The HTTP response body was empty.");
        }

        try
        {
            using JsonDocument document = JsonDocument.Parse(responseJson);
            JsonElement root = document.RootElement;

            string content = TryReadOllamaContent(root);
            if (content == null)
            {
                throw LocalLlmRuntimeException.For(
                    LocalLlmFailureKind.InvalidJson,
                    "The response did not contain message.content.");
            }

            if (string.IsNullOrWhiteSpace(content))
            {
                throw LocalLlmRuntimeException.For(
                    LocalLlmFailureKind.EmptyResponse,
                    "The response content was empty.");
            }

            return content.Trim();
        }
        catch (JsonException exception)
        {
            throw new LocalLlmRuntimeException(
                LocalLlmFailureKind.InvalidJson,
                "Локальная модель вернула ответ неожиданного формата.",
                exception.Message,
                exception);
        }
    }

    private static string TryReadOllamaContent(JsonElement root)
    {
        if (root.ValueKind != JsonValueKind.Object ||
            !root.TryGetProperty("message", out JsonElement message) ||
            message.ValueKind != JsonValueKind.Object ||
            !message.TryGetProperty("content", out JsonElement content) ||
            content.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        return content.GetString();
    }

    private LocalLlmRuntimeException CreateTimeoutFailure(string phase, Exception exception)
    {
        return new LocalLlmRuntimeException(
            LocalLlmFailureKind.Timeout,
            "Локальная модель не ответила вовремя. Попробуйте ещё раз.",
            $"Timeout {phase} after {_config.TimeoutSeconds:0.##} seconds.",
            exception);
    }

    private static void LogFailure(Uri endpoint, LocalLlmRuntimeException failure)
    {
        string endpointText = endpoint == null ? "<invalid endpoint>" : endpoint.ToString();
        GD.PrintErr(
            $"LocalLlmRuntime failure: kind={failure.Kind}; endpoint={endpointText}; details={failure.TechnicalDetails}");
    }

    private sealed record OllamaChatRequest(
        string Model,
        IReadOnlyList<OllamaMessage> Messages,
        bool Stream,
        OllamaOptions Options);

    private sealed record OllamaMessage(string Role, string Content);

    private sealed record OllamaOptions(
        [property: JsonPropertyName("temperature")] float Temperature,
        [property: JsonPropertyName("top_p")] float TopP,
        [property: JsonPropertyName("num_predict")] int MaxTokens);
}
