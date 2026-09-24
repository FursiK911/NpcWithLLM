using System.Collections.Generic;
using System;
using System.Threading;
using System.Threading.Tasks;

public enum RuntimePreparationStage
{
    StartingRuntime,
    CheckingModel,
    LoadingModel,
}

public readonly record struct RuntimePreparationProgress(
    RuntimePreparationStage Stage,
    double? Fraction = null);

public interface ILocalLlmRuntime
{
    Task<string> GenerateAsync(IReadOnlyList<DialogueMessage> context, CancellationToken cancellationToken = default,
        Action<string> onText = null);

    Task PrepareAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;

    Task PrepareAsync(Action<RuntimePreparationProgress> reportProgress,
        CancellationToken cancellationToken = default) => PrepareAsync(cancellationToken);

    void Shutdown() { }
}
