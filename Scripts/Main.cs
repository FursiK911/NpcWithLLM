using System;
using System.Collections.Generic;
using Godot;

public partial class Main : Node2D
{
    private ChatResponder _chatResponder = null!;
    private TextEdit _messageInput = null!;
    private Button _sendButton = null!;
    private RichTextLabel _responseText = null!;
    private Label _statusLabel = null!;
    private TextureRect _background = null!;
    private TextureRect _mechanicPortrait = null!;
    private Control _introOverlay = null!;
    private Label _introNarrativeLabel = null!;
    private Button _introOkButton = null!;
    private Control.FocusModeEnum _messageInputFocusMode;
    private Control.FocusModeEnum _sendButtonFocusMode;
    private bool _introDismissed;
    private bool _preparationComplete;
    private bool _requestInFlight;
    private Texture2D _idlePortrait = null!;
    private Texture2D _thinkingPortrait = null!;
    private Texture2D _portraitBeforeRequest = null!;
    private Texture2D[] _speakingPortraits = null!;
    private Dictionary<string, Texture2D> _emotionPortraits = null!;
    private readonly RandomNumberGenerator _random = new();

    public override void _Ready()
    {
        _chatResponder = GetNode<ChatResponder>("ChatResponder");
        _messageInput = GetNode<TextEdit>("UiLayer/DialoguePanel/Margin/VBox/Input/MessageInput");
        _sendButton = GetNode<Button>("UiLayer/DialoguePanel/Margin/VBox/Input/SendButton");
        _responseText = GetNode<RichTextLabel>("UiLayer/DialoguePanel/Margin/VBox/ResponseScroll/ResponseText");
        _statusLabel = GetNode<Label>("UiLayer/DialoguePanel/Margin/VBox/StatusLabel");
        _background = GetNode<TextureRect>("UiLayer/Background");
        _mechanicPortrait = GetNode<TextureRect>("UiLayer/MechanicPortrait");
        _introOverlay = GetNode<Control>("UiLayer/IntroOverlay");
        _introNarrativeLabel = GetNode<Label>("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/IntroNarrative");
        _introOkButton = GetNode<Button>("UiLayer/IntroOverlay/CenterContainer/IntroPanel/Margin/VBox/OkRow/IntroOkButton");
        _introOverlay.Visible = true;

        _background.Texture = LoadTexture("res://Art/Background/background.png");
        _idlePortrait = LoadTexture("res://Art/Mechanic/idle.png");
        _thinkingPortrait = LoadTexture("res://Art/Mechanic/thinking.png");
        Texture2D angryPortrait = LoadTexture("res://Art/Mechanic/angry.png");
        Texture2D happyPortrait = LoadTexture("res://Art/Mechanic/happy.png");
        Texture2D sadPortrait = LoadTexture("res://Art/Mechanic/sad.png");
        _speakingPortraits = new[]
        {
            LoadTexture("res://Art/Mechanic/speak_1.png"),
            LoadTexture("res://Art/Mechanic/speak_2.png"),
            LoadTexture("res://Art/Mechanic/speak_3.png"),
            LoadTexture("res://Art/Mechanic/speak_4.png"),
            LoadTexture("res://Art/Mechanic/speak_5.png"),
        };
        _emotionPortraits = new Dictionary<string, Texture2D>(StringComparer.OrdinalIgnoreCase)
        {
            ["angry"] = angryPortrait,
            ["happy"] = happyPortrait,
            ["sad"] = sadPortrait,
            ["thinking"] = _thinkingPortrait,
        };
        _mechanicPortrait.Texture = _idlePortrait;
        _responseText.Text = string.Empty;
        _random.Randomize();

        _messageInputFocusMode = _messageInput.FocusMode;
        _sendButtonFocusMode = _sendButton.FocusMode;
        _messageInput.FocusMode = Control.FocusModeEnum.None;
        _sendButton.FocusMode = Control.FocusModeEnum.None;

        NpcProfile profile = _chatResponder.ActiveProfile ?? throw new System.InvalidOperationException(
            "Для вступления не назначен профиль персонажа.");
        _introNarrativeLabel.Text = profile.PlayerIntroduction;

        _sendButton.Pressed += OnSendButtonPressed;
        _introOkButton.Pressed += OnIntroOkPressed;
        _messageInput.GuiInput += OnMessageInputGuiInput;
        _chatResponder.ResponseStarted += OnResponseStarted;
        _chatResponder.ResponseEmotionReceived += OnResponseEmotionReceived;
        _chatResponder.PreparationStarted += OnPreparationStarted;
        _chatResponder.PreparationFinished += OnPreparationFinished;
        _chatResponder.ResponseReceived += OnResponseReceived;
        _chatResponder.ResponseFailed += OnResponseFailed;
        _statusLabel.Text = "Готов к диалогу.";
        UpdateInteractionEnabled();
        _chatResponder.Prepare();
    }

    public override void _ExitTree()
    {
        _sendButton.Pressed -= OnSendButtonPressed;
        _introOkButton.Pressed -= OnIntroOkPressed;
        _messageInput.GuiInput -= OnMessageInputGuiInput;
        _chatResponder.ResponseStarted -= OnResponseStarted;
        _chatResponder.ResponseEmotionReceived -= OnResponseEmotionReceived;
        _chatResponder.PreparationStarted -= OnPreparationStarted;
        _chatResponder.PreparationFinished -= OnPreparationFinished;
        _chatResponder.ResponseReceived -= OnResponseReceived;
        _chatResponder.ResponseFailed -= OnResponseFailed;
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
        _statusLabel.Text = "Механик думает…";
        _chatResponder.RequestResponse(message);
    }

    private void OnResponseStarted()
    {
        _portraitBeforeRequest = _mechanicPortrait.Texture;
        _mechanicPortrait.Texture = _thinkingPortrait;
        _statusLabel.Text = "Механик думает…";
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

    private void OnResponseEmotionReceived(string emotion)
    {
        _mechanicPortrait.Texture = GetPortraitForEmotion(emotion);
    }

    private void OnResponseReceived(string response)
    {
        _responseText.Text = response;
        _messageInput.Text = string.Empty;
        _statusLabel.Text = "Готово.";
        _portraitBeforeRequest = null;
        FinishRequest();
    }

    private void OnResponseFailed(string error)
    {
        _mechanicPortrait.Texture = _portraitBeforeRequest ?? _idlePortrait;
        _portraitBeforeRequest = null;
        _statusLabel.Text = $"Не удалось получить ответ: {error}";
        FinishRequest();
    }

    private Texture2D GetPortraitForEmotion(string emotion)
    {
        string normalized = emotion?.Trim() ?? string.Empty;
        if (_emotionPortraits.TryGetValue(normalized, out Texture2D portrait))
        {
            return portrait;
        }

        return _speakingPortraits[_random.RandiRange(0, _speakingPortraits.Length - 1)];
    }

    private static Texture2D LoadTexture(string path)
    {
        return GD.Load<Texture2D>(path) ?? throw new InvalidOperationException(
            $"Не удалось загрузить изображение персонажа: {path}");
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
