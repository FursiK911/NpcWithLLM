using System.Collections.Generic;
using System;
using System.Threading;
using System.Threading.Tasks;

public sealed class FakeLocalLlmRuntime : ILocalLlmRuntime
{
    public FakeLocalLlmRuntime(string response = "Тестовый ответ персонажа.")
    {
        Response = response;
    }

    public string Response { get; set; }
    public Exception Failure { get; set; }
    public LocalLlmFailureKind? FailureKind { get; set; }
    public int DelayMilliseconds { get; set; }
    public int RequestCount { get; private set; }
    public IReadOnlyList<DialogueMessage> LastContext { get; private set; }

    public async Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context, CancellationToken cancellationToken = default,
        Action<string> onText = null)
    {
        LastContext = context;
        RequestCount++;

        if (DelayMilliseconds > 0)
        {
            await Task.Delay(DelayMilliseconds, cancellationToken);
        }

        if (Failure != null)
        {
            throw Failure;
        }

        if (FailureKind.HasValue)
        {
            throw LocalLlmRuntimeException.CreateForKind(FailureKind.Value, "Configured fake runtime failure.");
        }

        onText?.Invoke(Response);
        return Response;
    }
}
