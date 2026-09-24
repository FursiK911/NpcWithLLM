using Godot;

public partial class Main : Node2D
{
    private ChatResponder _chatResponder = null!;
    private TextEdit _messageInput = null!;
    private Button _sendButton = null!;
    private RichTextLabel _responseText = null!;
    private Label _statusLabel = null!;
    private Control _introOverlay = null!;
    private Label _introCharacterLabel = null!;
    private Label _introSituationLabel = null!;
    private Button _introOkButton = null!;
    private Control.FocusModeEnum _messageInputFocusMode;
    private Control.FocusModeEnum _sendButtonFocusMode;
    private bool _introDismissed;
    private bool _preparationComplete;
    private bool _requestInFlight;
    private bool _hasPartialText;
    private readonly System.Diagnostics.Stopwatch _responseTimer = new();

    public override void _Ready()
    {
        _chatResponder = GetNode<ChatResponder>("ChatResponder");
        _messageInput = GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
        _sendButton = GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
        _responseText = GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        _statusLabel = GetNode<Label>("UiLayer/DialoguePanel/Margin/VBox/StatusLabel");
        _introOverlay = GetNode<Control>("UiLayer/IntroOverlay");
        _introCharacterLabel = GetNode<Label>("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/IntroCharacter");
        _introSituationLabel = GetNode<Label>("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/IntroSituation");
        _introOkButton = GetNode<Button>("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/OkRow/IntroOkButton");
        _introOverlay.Visible = true;

        _messageInputFocusMode = _messageInput.FocusMode;
        _sendButtonFocusMode = _sendButton.FocusMode;
        _messageInput.FocusMode = Control.FocusModeEnum.None;
        _sendButton.FocusMode = Control.FocusModeEnum.None;

        NpcProfile profile = _chatResponder.ActiveProfile ?? throw new System.InvalidOperationException(
            "Для вступления не назначен профиль персонажа.");
        _introCharacterLabel.Text = $"{profile.Name} — {profile.Role}";
        _introSituationLabel.Text = profile.Situation;

        _sendButton.Pressed += OnSendButtonPressed;
        _introOkButton.Pressed += OnIntroOkPressed;
        _messageInput.GuiInput += OnMessageInputGuiInput;
        _chatResponder.ResponseStarted += OnResponseStarted;
        _chatResponder.ResponseChunkReceived += OnResponseChunkReceived;
        _chatResponder.PreparationStarted += OnPreparationStarted;
        _chatResponder.PreparationFinished += OnPreparationFinished;
        _chatResponder.ResponseReceived += OnResponseReceived;
        _chatResponder.ResponseFailed += OnResponseFailed;
        GetViewport().SizeChanged += QueueRedraw;

        _statusLabel.Text = "Готов к диалогу.";
        UpdateInteractionEnabled();
        QueueRedraw();
        _chatResponder.Prepare();
    }

    public override void _ExitTree()
    {
        _sendButton.Pressed -= OnSendButtonPressed;
        _introOkButton.Pressed -= OnIntroOkPressed;
        _messageInput.GuiInput -= OnMessageInputGuiInput;
        _chatResponder.ResponseStarted -= OnResponseStarted;
        _chatResponder.ResponseChunkReceived -= OnResponseChunkReceived;
        _chatResponder.PreparationStarted -= OnPreparationStarted;
        _chatResponder.PreparationFinished -= OnPreparationFinished;
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

    private void OnIntroOkPressed()
    {
        _introDismissed = true;
        _introOverlay.Visible = false;
        _messageInput.FocusMode = _messageInputFocusMode;
        _sendButton.FocusMode = _sendButtonFocusMode;
        UpdateInteractionEnabled();

        if (CanInteract)
        {
            _messageInput.GrabFocus();
        }
    }

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
        if (!CanInteract || _chatResponder.IsBusy)
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
        UpdateInteractionEnabled();
        _statusLabel.Text = "Иван думает…";
        _chatResponder.RequestResponse(message);
    }

    private void OnResponseStarted()
    {
        _responseTimer.Restart();
        _hasPartialText = false;
        _statusLabel.Text = "Иван думает…";
        UpdateInteractionEnabled();
    }

    private void OnPreparationStarted()
    {
        _preparationComplete = false;
        _statusLabel.Text = "Подготовка персонажа…";
        UpdateInteractionEnabled();
    }

    private void OnPreparationFinished()
    {
        _preparationComplete = true;
        _statusLabel.Text = "Готов к диалогу.";
        UpdateInteractionEnabled();

        if (CanInteract)
        {
            _messageInput.GrabFocus();
        }
    }

    private void OnResponseChunkReceived(string text)
    {
        if (!_hasPartialText)
        {
            if (string.IsNullOrWhiteSpace(text)) return;
            _responseText.Text = string.Empty;
            _hasPartialText = true;
            GD.Print($"Dialogue first visible text: {_responseTimer.ElapsedMilliseconds} ms.");
        }
        _responseText.Text += text;
        _statusLabel.Text = "Иван отвечает…";
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
        _statusLabel.Text = _hasPartialText
            ? $"Ответ не завершён: {error}"
            : $"Не удалось получить ответ: {error}";
        FinishRequest();
    }

    private void FinishRequest()
    {
        _requestInFlight = false;
        UpdateInteractionEnabled();

        if (CanInteract)
        {
            _messageInput.GrabFocus();
        }
    }

    private bool CanInteract => _introDismissed && _preparationComplete && !_requestInFlight;

    private void UpdateInteractionEnabled()
    {
        bool enabled = CanInteract;
        _messageInput.Editable = enabled;
        _sendButton.Disabled = !enabled;

        if (!enabled)
        {
            _messageInput.ReleaseFocus();
        }
    }
}
