using System;
using System.Threading;
using System.Threading.Tasks;
using Godot;

public partial class LocalLlmResponder : ChatResponder
{
    private readonly NpcMemory _memory = new();
    private readonly ContextBuilder _contextBuilder = new();
    private DialogueHistory _history;
    private ILocalLlmRuntime _runtime;
    private NpcProfile _profile;
    private readonly CancellationTokenSource _lifetime = new();
    private bool _prepared;

    [Export]
    public NpcProfile Profile { get; set; }

    public override void _ExitTree() => _lifetime.Cancel();

    public override void Prepare()
    {
        if (IsBusy) return;
        IsBusy = true;
        EmitSignal(SignalName.PreparationStarted);
        _ = PrepareRuntimeAsync();
    }

    private async Task PrepareRuntimeAsync()
    {
        try
        {
            await GetRuntime().PrepareAsync(_lifetime.Token);
            _prepared = true;
            IsBusy = false;
            if (!_lifetime.IsCancellationRequested) EmitSignal(SignalName.PreparationFinished);
        }
        catch (Exception exception)
        {
            IsBusy = false;
            ReportFailure(exception);
        }
    }

    [Export]
    public LocalLlmConfig Config { get; set; } = new();

    public NpcMemory Memory => _memory;

    public DialogueHistory History
    {
        get
        {
            LocalLlmConfig config = Config ?? new LocalLlmConfig();
            return _history ??= new DialogueHistory(config.MaxHistoryMessages, config.MaxHistoryCharacters);
        }
    }

    public void Configure(ILocalLlmRuntime runtime, NpcProfile profile)
    {
        _runtime = runtime ?? throw new ArgumentNullException(nameof(runtime));
        _profile = profile ?? throw new ArgumentNullException(nameof(profile));
    }

    public override void RequestResponse(string message)
    {
        if (IsBusy || string.IsNullOrWhiteSpace(message))
        {
            return;
        }

        IsBusy = true;
        EmitSignal(SignalName.ResponseStarted);
        _ = GenerateResponseAsync(message.Trim());
    }

    private async Task GenerateResponseAsync(string message)
    {
        try
        {
            if (!_prepared)
            {
                await GetRuntime().PrepareAsync(_lifetime.Token);
                _prepared = true;
            }
            NpcProfile profile = RequireProfile();
            DialogueContext context = _contextBuilder.Build(
                profile.ToPersona(), profile.Situation, _memory, History, message);
            string response = await GetRuntime().GenerateAsync(context.Messages, _lifetime.Token,
                text => { if (!_lifetime.IsCancellationRequested) EmitSignal(SignalName.ResponseChunkReceived, text); });
            _lifetime.Token.ThrowIfCancellationRequested();
            if (string.IsNullOrWhiteSpace(response))
            {
                throw LocalLlmRuntimeException.CreateForKind(
                    LocalLlmFailureKind.EmptyResponse,
                    "Responder received an empty response.");
            }

            // Фиксируем состояние только после успешной генерации.
            _memory.LearnFrom(message);
            History.AddPair(message, response);
            IsBusy = false;
            EmitSignal(SignalName.ResponseReceived, response.Trim());
        }
        catch (Exception exception)
        {
            IsBusy = false;
            ReportFailure(exception);
        }
    }

    private void ReportFailure(Exception exception)
    {
        if (_lifetime.IsCancellationRequested) return;
        string userMessage = exception is LocalLlmRuntimeException runtimeException
            ? runtimeException.UserMessage : "Не удалось получить ответ от локальной модели.";
        EmitSignal(SignalName.ResponseFailed, userMessage);
    }

    private ILocalLlmRuntime GetRuntime()
    {
        return _runtime ??= new LocalLlmRuntime(Config ?? new LocalLlmConfig());
    }

    private NpcProfile RequireProfile()
    {
        return _profile ?? Profile ?? throw new ArgumentException(
            "Персонажу не назначен профиль: узел ChatResponder должен ссылаться на res://NpcProfile.tres.",
            nameof(Profile));
    }

    public static NpcProfile DefaultProfile => new()
    {
        Name = "Иван",
        Role = "механик в мастерской",
        Character = "наблюдательный и практичный",
        SpeechStyle = "короткие спокойные фразы",
        PlayerAttitude = "настороженно, но разговаривает",
        Knowledge = "знает мастерскую; не знает, кто вошедший",
        BehaviorConstraints = "не выдумывает факты о мире",
        Situation = "Иван в мастерской.",
    };
}
