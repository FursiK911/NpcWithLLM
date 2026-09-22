using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public sealed class FakeLocalLlmRuntime : ILocalLlmRuntime
{
    public FakeLocalLlmRuntime(string response = "Тестовый ответ персонажа.")
    {
        Response = response;
    }

    public string Response { get; set; }
    public IReadOnlyList<DialogueMessage> LastContext { get; private set; }

    public Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context, CancellationToken cancellationToken = default)
    {
        LastContext = context;
        return Task.FromResult(Response);
    }
}
