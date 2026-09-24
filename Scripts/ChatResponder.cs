using Godot;

public partial class ChatResponder : Node
{
    [Export]
    public NpcProfile Profile { get; set; }

    public virtual NpcProfile ActiveProfile => Profile;

    [Signal]
    public delegate void ResponseStartedEventHandler();

    [Signal]
    public delegate void ResponseChunkReceivedEventHandler(string text);

    [Signal]
    public delegate void ResponseEmotionReceivedEventHandler(string emotion);

    [Signal]
    public delegate void PreparationStartedEventHandler();

    [Signal]
    public delegate void PreparationFinishedEventHandler();

    [Signal]
    public delegate void ResponseReceivedEventHandler(string response);

    [Signal]
    public delegate void ResponseFailedEventHandler(string error);

    public bool IsBusy { get; protected set; }

    public virtual void Prepare() => EmitSignal(SignalName.PreparationFinished);

    public virtual void RequestResponse(string message)
    {
        throw new System.NotImplementedException();
    }
}
