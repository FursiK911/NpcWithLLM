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
    PrismServerUnavailable,
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
            LocalLlmFailureKind.HttpError => "Сервис локальной LLM отклонил запрос. Проверьте его состояние и перезапустите игру.",
            LocalLlmFailureKind.NetworkError => "Не удалось подключиться к сервису локальной LLM. Проверьте запуск Ollama.",
            LocalLlmFailureKind.Timeout => "Локальная модель не ответила вовремя. Попробуйте ещё раз.",
            LocalLlmFailureKind.InvalidJson => "Локальная модель вернула ответ неожиданного формата.",
            LocalLlmFailureKind.EmptyResponse => "Локальная модель вернула пустой ответ.",
            LocalLlmFailureKind.IncompleteResponse => "Ответ персонажа оборвался. Попробуйте ещё раз.",
            LocalLlmFailureKind.OllamaExecutableMissing => "В файлах игры не найдена программа Ollama. Восстановите поставку игры.",
            LocalLlmFailureKind.OllamaExecutableIntegrity => "Файл Ollama повреждён или изменён. Восстановите файл поставки.",
            LocalLlmFailureKind.OllamaProcessStart => "Не удалось запустить сервис локальной LLM Ollama.",
            LocalLlmFailureKind.OllamaServerUnavailable => "Сервис локальной LLM Ollama не запустился вовремя.",
            LocalLlmFailureKind.ModelUnavailable => "Запрошенная модель не найдена в локальной Ollama.",
            LocalLlmFailureKind.PrismServerUnavailable => "Локальный сервер PrismML не запущен. Запустите его и повторите попытку.",
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
