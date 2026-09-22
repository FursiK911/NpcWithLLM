using Godot;

[GlobalClass]
public partial class NpcProfile : Resource
{
    [Export]
    public string Name { get; set; } = "";

    [Export]
    public string Role { get; set; } = "";

    [Export]
    public string Character { get; set; } = "";

    [Export]
    public string SpeechStyle { get; set; } = "";

    [Export]
    public string PlayerAttitude { get; set; } = "";

    [Export]
    public string Knowledge { get; set; } = "";

    [Export]
    public string BehaviorConstraints { get; set; } = "";

    [Export(PropertyHint.MultilineText)]
    public string Situation { get; set; } = "";

    public NpcPersona ToPersona() => new(
        Name, Role, Character, SpeechStyle, PlayerAttitude, Knowledge, BehaviorConstraints);
}
