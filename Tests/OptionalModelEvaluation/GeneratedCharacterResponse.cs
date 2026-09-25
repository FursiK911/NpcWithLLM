using System;
using System.Text.Json;

public sealed class GeneratedCharacterResponse
{
    private GeneratedCharacterResponse(string message, string emotion)
    {
        Message = message;
        Emotion = emotion;
    }

    public string Message { get; }
    public string Emotion { get; }

    public static GeneratedCharacterResponse Parse(string rawResponse)
    {
        JsonDocument document;
        try
        {
            document = JsonDocument.Parse(rawResponse ?? string.Empty);
        }
        catch (JsonException exception)
        {
            throw LocalLlmRuntimeException.CreateForKind(
                LocalLlmFailureKind.InvalidJson,
                $"Character response was not valid JSON: {exception.Message}");
        }

        using (document)
        {
            JsonElement root = document.RootElement;
            if (root.ValueKind != JsonValueKind.Object ||
                !root.TryGetProperty("message", out JsonElement messageElement) ||
                messageElement.ValueKind != JsonValueKind.String)
            {
                throw EmptyResponseException();
            }

            string message = messageElement.GetString();
            if (string.IsNullOrWhiteSpace(message))
            {
                throw EmptyResponseException();
            }

            string emotion = "neutral";
            if (root.TryGetProperty("emotion", out JsonElement emotionElement) &&
                emotionElement.ValueKind == JsonValueKind.String)
            {
                string candidate = emotionElement.GetString()?.Trim().ToLowerInvariant() ?? string.Empty;
                emotion = candidate is "angry" or "happy" or "sad" or "thinking" or "neutral"
                    ? candidate
                    : "neutral";
            }

            return new GeneratedCharacterResponse(message.Trim(), emotion);
        }
    }

    private static LocalLlmRuntimeException EmptyResponseException()
        => LocalLlmRuntimeException.CreateForKind(
            LocalLlmFailureKind.EmptyResponse,
            "Character response did not contain a non-empty string message.");
}
