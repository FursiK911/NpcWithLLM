using System;
using System.Threading.Tasks;
using Godot;

public partial class MockChatResponder : ChatResponder
{
    private const double ResponseDelaySeconds = 0.8;

    public override void RequestResponse(string message)
    {
        if (IsBusy)
        {
            return;
        }

        IsBusy = true;
        EmitSignal(SignalName.ResponseStarted);
        _ = RespondAfterDelayAsync(message);
    }

    private async Task RespondAfterDelayAsync(string message)
    {
        try
        {
            await ToSignal(GetTree().CreateTimer(ResponseDelaySeconds), SceneTreeTimer.SignalName.Timeout);
            EmitSignal(SignalName.ResponseReceived, $"Персонаж услышал: «{message}»");
        }
        catch (Exception exception)
        {
            EmitSignal(SignalName.ResponseFailed, exception.Message);
        }
        finally
        {
            IsBusy = false;
        }
    }
}
