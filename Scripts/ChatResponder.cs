using Godot;

public partial class ChatResponder : Node
{
    [Signal]
    public delegate void ResponseStartedEventHandler();

    [Signal]
    public delegate void ResponseReceivedEventHandler(string response);

    [Signal]
    public delegate void ResponseFailedEventHandler(string error);

    public bool IsBusy { get; protected set; }

    public virtual void RequestResponse(string message)
    {
        throw new System.NotImplementedException();
    }
}
