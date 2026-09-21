using Godot;

public partial class Main : Node3D
{
    private ChatResponder _chatResponder = null!;
    private TextEdit _messageInput = null!;
    private Button _sendButton = null!;
    private RichTextLabel _responseText = null!;
    private Label _statusLabel = null!;
    private bool _requestInFlight;

    public override void _Ready()
    {
        _chatResponder = GetNode<ChatResponder>("ChatResponder");
        _messageInput = GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/InputRow/MessageInput");
        _sendButton = GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/InputRow/SendButton");
        _responseText = GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        _statusLabel = GetNode<Label>("UiLayer/DialoguePanel/Margin/VBox/StatusLabel");

        _sendButton.Pressed += OnSendButtonPressed;
        _messageInput.GuiInput += OnMessageInputGuiInput;
        _chatResponder.ResponseStarted += OnResponseStarted;
        _chatResponder.ResponseReceived += OnResponseReceived;
        _chatResponder.ResponseFailed += OnResponseFailed;

        _statusLabel.Text = "Готов к диалогу.";
        _messageInput.GrabFocus();
    }

    public override void _ExitTree()
    {
        _sendButton.Pressed -= OnSendButtonPressed;
        _messageInput.GuiInput -= OnMessageInputGuiInput;
        _chatResponder.ResponseStarted -= OnResponseStarted;
        _chatResponder.ResponseReceived -= OnResponseReceived;
        _chatResponder.ResponseFailed -= OnResponseFailed;
    }

    private void OnSendButtonPressed()
    {
        SubmitMessage();
    }

    private void OnMessageInputGuiInput(InputEvent inputEvent)
    {
        if (inputEvent is not InputEventKey keyEvent || !keyEvent.Pressed || keyEvent.Echo)
        {
            return;
        }

        if (keyEvent.Keycode != Key.Enter || keyEvent.ShiftPressed)
        {
            return;
        }

        GetViewport().SetInputAsHandled();
        SubmitMessage();
    }

    private void SubmitMessage()
    {
        if (_requestInFlight)
        {
            return;
        }

        string message = _messageInput.Text.Trim();
        if (string.IsNullOrEmpty(message))
        {
            _statusLabel.Text = "Введите сообщение.";
            return;
        }

        _requestInFlight = true;
        SetInteractionEnabled(false);
        _statusLabel.Text = "Персонаж думает…";
        _chatResponder.RequestResponse(message);
    }

    private void OnResponseStarted()
    {
        _statusLabel.Text = "Персонаж думает…";
    }

    private void OnResponseReceived(string response)
    {
        _responseText.Text = response;
        _messageInput.Text = string.Empty;
        _statusLabel.Text = "Готово.";
        FinishRequest();
    }

    private void OnResponseFailed(string error)
    {
        _statusLabel.Text = $"Не удалось получить ответ: {error}";
        FinishRequest();
    }

    private void FinishRequest()
    {
        _requestInFlight = false;
        SetInteractionEnabled(true);
        _messageInput.GrabFocus();
    }

    private void SetInteractionEnabled(bool enabled)
    {
        _messageInput.Editable = enabled;
        _sendButton.Disabled = !enabled;
    }
}
