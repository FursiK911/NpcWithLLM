using System;

public enum LocalLlmFailureKind
{
    Configuration,
    HttpError,
    NetworkError,
    Timeout,
    InvalidJson,
    EmptyResponse,
    IncompleteResponse,
    OllamaExecutableMissing,
    OllamaExecutableIntegrity,
    OllamaProcessStart,
    OllamaServerUnavailable,
    ModelUnavailable,
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
            LocalLlmFailureKind.NetworkError => "Не удалось подключиться к локальному сервису модели. Проверьте, запущен ли он.",
            LocalLlmFailureKind.Timeout => "Локальная модель не ответила вовремя. Попробуйте ещё раз.",
            LocalLlmFailureKind.InvalidJson => "Локальная модель вернула ответ неожиданного формата.",
            LocalLlmFailureKind.EmptyResponse => "Локальная модель вернула пустой ответ.",
            LocalLlmFailureKind.IncompleteResponse => "Ответ персонажа оборвался. Попробуйте ещё раз.",
            LocalLlmFailureKind.OllamaExecutableMissing => "Не найден локальный runtime Ollama. Восстановите файлы поставки.",
            LocalLlmFailureKind.OllamaExecutableIntegrity => "Файл Ollama повреждён или изменён. Восстановите файл поставки.",
            LocalLlmFailureKind.OllamaProcessStart => "Не удалось запустить локальный сервис Ollama.",
            LocalLlmFailureKind.OllamaServerUnavailable => "Локальный сервис Ollama не запустился вовремя.",
            LocalLlmFailureKind.ModelUnavailable => "Запрошенная модель не найдена в локальной Ollama.",
            _ => "Не удалось получить ответ от локальной модели.",
        };

        return new LocalLlmRuntimeException(kind, userMessage, technicalDetails);
    }

    public static LocalLlmRuntimeException CreateModelUnavailable(string modelName)
    {
        string configuredName = string.IsNullOrWhiteSpace(modelName) ? "(не указана)" : modelName;
        return new LocalLlmRuntimeException(
            LocalLlmFailureKind.ModelUnavailable,
            $"Модель «{configuredName}» не найдена в локальной Ollama. Установите её и повторите запуск.",
            $"Configured model '{configuredName}' is not present in the local Ollama model list.");
    }
}
