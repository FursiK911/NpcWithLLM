using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public interface ILocalLlmRuntime
{
    Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context, CancellationToken cancellationToken = default);
}
