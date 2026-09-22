using System;

public enum LocalLlmFailureKind
{
    Configuration,
    HttpError,
    NetworkError,
    Timeout,
    InvalidJson,
    EmptyResponse,
    Unknown,
}

public sealed class LocalLlmRuntimeException : Exception
{
    public LocalLlmRuntimeException(
        LocalLlmFailureKind kind,
        string userMessage,
        string technicalDetails,
        Exception innerException = null)
        : base(technicalDetails, innerException)
    {
        Kind = kind;
        UserMessage = userMessage;
        TechnicalDetails = technicalDetails;
    }

    public LocalLlmFailureKind Kind { get; }
    public string UserMessage { get; }
    public string TechnicalDetails { get; }

    public static LocalLlmRuntimeException CreateForKind(
        LocalLlmFailureKind kind,
        string technicalDetails = "fake runtime failure")
    {
        string userMessage = kind switch
        {
            LocalLlmFailureKind.Configuration => "Неверно настроено подключение к локальной модели.",
            LocalLlmFailureKind.HttpError => "Сервис локальной модели вернул ошибку HTTP.",
            LocalLlmFailureKind.NetworkError => "Не удалось подключиться к локальной модели. Проверьте, запущен ли Ollama.",
            LocalLlmFailureKind.Timeout => "Локальная модель не ответила вовремя. Попробуйте ещё раз.",
            LocalLlmFailureKind.InvalidJson => "Локальная модель вернула ответ неожиданного формата.",
            LocalLlmFailureKind.EmptyResponse => "Локальная модель вернула пустой ответ.",
            _ => "Не удалось получить ответ от локальной модели.",
        };

        return new LocalLlmRuntimeException(kind, userMessage, technicalDetails);
    }
}
