using System;
using Godot;

[GlobalClass]
public partial class LocalLlmConfig : Resource
{
    [Export]
    public string BaseUrl { get; set; } = "http://127.0.0.1:11434";

    [Export]
    public string EndpointPath { get; set; } = "/api/chat";

    [Export]
    public string ModelName { get; set; } = "qwen3.5:4b";

    [Export(PropertyHint.Range, "1,300,1")]
    public float TimeoutSeconds { get; set; } = 60.0f;

    [Export(PropertyHint.Range, "0,2,0.05")]
    public float Temperature { get; set; } = 0.7f;

    [Export(PropertyHint.Range, "0,1,0.05")]
    public float TopP { get; set; } = 0.8f;

    [Export(PropertyHint.Range, "1,4096,1")]
    public int MaxTokens { get; set; } = 256;

    [Export(PropertyHint.Range, "2048,16384,1024")]
    public int ContextTokens { get; set; } = 8192;

    [Export(PropertyHint.Range, "-2,2,0.1")]
    public float PresencePenalty { get; set; } = 0;

    public Uri GetEndpointUri()
    {
        if (!Uri.TryCreate(BaseUrl?.TrimEnd('/') + "/", UriKind.Absolute, out Uri baseUri) ||
            (baseUri.Scheme != Uri.UriSchemeHttp && baseUri.Scheme != Uri.UriSchemeHttps) ||
            !baseUri.IsLoopback)
        {
            throw new ArgumentException(
                "BaseUrl должен быть loopback HTTP(S)-адресом локального сервиса.",
                nameof(BaseUrl));
        }

        if (string.IsNullOrWhiteSpace(EndpointPath))
        {
            throw new ArgumentException("EndpointPath не может быть пустым.", nameof(EndpointPath));
        }

        if (!Uri.TryCreate(EndpointPath, UriKind.RelativeOrAbsolute, out Uri endpointPath) ||
            endpointPath.IsAbsoluteUri)
        {
            throw new ArgumentException(
                "EndpointPath должен быть относительным путём локального API.",
                nameof(EndpointPath));
        }

        if (string.IsNullOrWhiteSpace(ModelName))
        {
            throw new ArgumentException("ModelName не может быть пустым.", nameof(ModelName));
        }

        if (TimeoutSeconds <= 0)
        {
            throw new ArgumentException("TimeoutSeconds должен быть больше нуля.", nameof(TimeoutSeconds));
        }

        if (Temperature < 0 || Temperature > 2)
        {
            throw new ArgumentException("Temperature должен быть в диапазоне от 0 до 2.", nameof(Temperature));
        }

        if (TopP <= 0 || TopP > 1)
        {
            throw new ArgumentException("TopP должен быть в диапазоне (0, 1].", nameof(TopP));
        }

        if (MaxTokens <= 0)
        {
            throw new ArgumentException("MaxTokens должен быть больше нуля.", nameof(MaxTokens));
        }

        if (ContextTokens < 2048 || ContextTokens > 16384 || MaxTokens >= ContextTokens)
        {
            throw new ArgumentException("Неверный бюджет контекста или ответа.", nameof(ContextTokens));
        }

        if (!float.IsFinite(PresencePenalty) || PresencePenalty < -2 || PresencePenalty > 2)
        {
            throw new ArgumentException("PresencePenalty должен быть в диапазоне [-2, 2].", nameof(PresencePenalty));
        }

        Uri endpoint = new(baseUri, EndpointPath.TrimStart('/'));
        if (!endpoint.IsLoopback)
        {
            throw new ArgumentException(
                "EndpointPath не должен указывать за пределы loopback-сервиса.",
                nameof(EndpointPath));
        }

        return endpoint;
    }
}
