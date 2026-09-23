using System;
using System.Threading.Tasks;
using Godot;

public partial class Bonsai2DefaultProviderSmoke : Node
{
    public override async void _Ready()
    {
        try
        {
            await RunDefaultProviderDialogue();
            GD.Print("PASS: Bonsai is the default game provider");
            GetTree().Quit();
        }
        catch (Exception exception)
        {
            GD.PrintErr(exception);
            GetTree().Quit(1);
        }
    }

    private async Task RunDefaultProviderDialogue()
    {
        var mainScene = GD.Load<PackedScene>("res://Main.tscn").Instantiate<Main>();
        var responder = mainScene.GetNode<LocalLlmResponder>("ChatResponder");
        if (responder.Config.Provider != LocalLlmProvider.Prism)
            throw new InvalidOperationException($"Expected Prism provider, got {responder.Config.Provider}.");
        if (responder.Config.BaseUrl != Bonsai2PrismRuntime.BaseUrl ||
            responder.Config.EndpointPath != "/v1/chat/completions")
        {
            throw new InvalidOperationException("Main.tscn does not point to the local Prism chat endpoint.");
        }

        var ready = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        void OnPrepared() => ready.TrySetResult();
        void OnPreparationFailed(string error) => ready.TrySetException(new InvalidOperationException(error));
        responder.PreparationFinished += OnPrepared;
        responder.ResponseFailed += OnPreparationFailed;
        AddChild(mainScene);
        await ready.Task.WaitAsync(TimeSpan.FromMinutes(2));
        responder.PreparationFinished -= OnPrepared;
        responder.ResponseFailed -= OnPreparationFailed;

        var input = mainScene.GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
        var sendButton = mainScene.GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
        var responseText = mainScene.GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        var response = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
        void OnResponse(string text) => response.TrySetResult(text);
        void OnFailure(string error) => response.TrySetException(new InvalidOperationException(error));
        responder.ResponseReceived += OnResponse;
        responder.ResponseFailed += OnFailure;
        input.Text = "Привет. Как тебя зовут?";
        sendButton.EmitSignal(Button.SignalName.Pressed);
        string answer = await response.Task.WaitAsync(TimeSpan.FromSeconds(180));
        responder.ResponseReceived -= OnResponse;
        responder.ResponseFailed -= OnFailure;

        if (string.IsNullOrWhiteSpace(answer) || input.Text.Length != 0 || responseText.Text != answer)
            throw new InvalidOperationException("Default Bonsai dialogue did not finish correctly in the game UI.");
        if (responder.History.MessageCount != 2)
            throw new InvalidOperationException("Default Bonsai dialogue was not committed to history exactly once.");

        mainScene.QueueFree();
    }
}
