using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Serialization;

public static class LocalLlmRequestBuilder
{
    public static LocalLlmRequestPayload Create(
        string model,
        IReadOnlyList<DialogueMessage> context,
        float temperature,
        float topP,
        int maxTokens,
        bool think = false,
        bool stream = false,
        int contextTokens = 4096,
        float presencePenalty = 0)
    {
        if (string.IsNullOrWhiteSpace(model))
        {
            throw new ArgumentException("Model не может быть пустым.", nameof(model));
        }

        if (context == null || context.Count == 0)
        {
            throw new ArgumentException("Контекст запроса пуст.", nameof(context));
        }

        string systemPrompt = string.Join(
            "\n\n",
            context
                .Where(message => string.Equals(message.Role, "system", StringComparison.OrdinalIgnoreCase))
                .Select(message => message.Content?.Trim())
                .Where(content => !string.IsNullOrWhiteSpace(content)));

        List<DialogueMessage> chatMessages = new();
        if (!string.IsNullOrWhiteSpace(systemPrompt))
        {
            chatMessages.Add(new DialogueMessage("system", systemPrompt));
        }
        chatMessages.AddRange(context.Where(message => !string.Equals(message.Role, "system", StringComparison.OrdinalIgnoreCase)));

        return new LocalLlmRequestPayload(
            model.Trim(),
            chatMessages,
            stream,
            new LocalLlmGenerationOptions(temperature, topP, maxTokens, contextTokens, presencePenalty),
            think);
    }
}

public sealed record LocalLlmRequestPayload(
    string Model,
    IReadOnlyList<DialogueMessage> Messages,
    bool Stream,
    LocalLlmGenerationOptions Options,
    bool Think);

public sealed record LocalLlmGenerationOptions(
    float Temperature,
    [property: JsonPropertyName("top_p")] float TopP,
    [property: JsonPropertyName("num_predict")] int MaxTokens,
    [property: JsonPropertyName("num_ctx")] int ContextTokens,
    [property: JsonPropertyName("presence_penalty")] float PresencePenalty,
    [property: JsonPropertyName("repeat_penalty")] float RepeatPenalty = 1.0f);
