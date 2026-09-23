using Godot;

/// <summary>
/// Opens the regular dialogue UI with an explicitly configured local Prism runtime.
/// </summary>
public partial class Bonsai2InteractiveRunner : Node
{
    public override void _Ready()
    {
        var mainScene = GD.Load<PackedScene>("res://Main.tscn")
            ?? throw new System.InvalidOperationException("Could not load res://Main.tscn.");
        var main = mainScene.Instantiate<Main>();
        var responder = main.GetNode<LocalLlmResponder>("ChatResponder");
        var evalConfig = responder.Config.Duplicate(true) as LocalLlmConfig
            ?? throw new System.InvalidOperationException("Could not duplicate LocalLlmConfig.tres.");

        responder.Config = evalConfig;
        responder.Configure(new Bonsai2PrismRuntime(evalConfig),
            responder.Profile
            ?? throw new System.InvalidOperationException("Main.tscn has no NpcProfile assigned."));
        AddChild(main);
    }
}
