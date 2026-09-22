using Godot;

public partial class Main : Node2D
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
        _messageInput = GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
        _sendButton = GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
        _responseText = GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        _statusLabel = GetNode<Label>("UiLayer/DialoguePanel/Margin/VBox/StatusLabel");

        _sendButton.Pressed += OnSendButtonPressed;
        _messageInput.GuiInput += OnMessageInputGuiInput;
        _chatResponder.ResponseStarted += OnResponseStarted;
        _chatResponder.ResponseReceived += OnResponseReceived;
        _chatResponder.ResponseFailed += OnResponseFailed;
        GetViewport().SizeChanged += QueueRedraw;

        _statusLabel.Text = "Готов к диалогу.";
        _messageInput.GrabFocus();
        QueueRedraw();
    }

    public override void _ExitTree()
    {
        _sendButton.Pressed -= OnSendButtonPressed;
        _messageInput.GuiInput -= OnMessageInputGuiInput;
        _chatResponder.ResponseStarted -= OnResponseStarted;
        _chatResponder.ResponseReceived -= OnResponseReceived;
        _chatResponder.ResponseFailed -= OnResponseFailed;
        GetViewport().SizeChanged -= QueueRedraw;
    }

    public override void _Draw()
    {
        Vector2 size = GetViewportRect().Size;
        DrawRect(new Rect2(Vector2.Zero, size), new Color("101827"));
        DrawRect(new Rect2(0, size.Y * 0.78f, size.X, size.Y * 0.22f), new Color("18263a"));

        float npcX = size.X * 0.29f;
        float npcY = size.Y * 0.48f;
        DrawCircle(new Vector2(npcX, npcY - 86), 44, new Color("e5b08b"));
        DrawCircle(new Vector2(npcX, npcY - 95), 45, new Color("4c342d"));
        DrawRect(new Rect2(npcX - 58, npcY - 40, 116, 150), new Color("3f7094"));
        DrawRect(new Rect2(npcX - 74, npcY + 100, 148, 18), new Color("26394c"));
        DrawLine(new Vector2(npcX - 24, npcY - 82), new Vector2(npcX - 14, npcY - 82), new Color("202b36"), 4);
        DrawLine(new Vector2(npcX + 14, npcY - 82), new Vector2(npcX + 24, npcY - 82), new Color("202b36"), 4);
    }

    private void OnSendButtonPressed() => SubmitMessage();

    private void OnMessageInputGuiInput(InputEvent inputEvent)
    {
        if (inputEvent is not InputEventKey keyEvent || !keyEvent.Pressed || keyEvent.Echo)
        {
            return;
        }

        // TextEdit keeps Shift+Enter as a newline. Plain Enter submits the message.
        if (keyEvent.Keycode != Key.Enter || keyEvent.ShiftPressed)
        {
            return;
        }

        GetViewport().SetInputAsHandled();
        SubmitMessage();
    }

    private void SubmitMessage()
    {
        if (_requestInFlight || _chatResponder.IsBusy)
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
        _statusLabel.Text = "Иван думает…";
        _chatResponder.RequestResponse(message);
    }

    private void OnResponseStarted()
    {
        _statusLabel.Text = "Иван думает…";
        SetInteractionEnabled(false);
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
