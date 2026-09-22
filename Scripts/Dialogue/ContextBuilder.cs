using System.Collections.Generic;

public sealed class DialogueContext
{
    public DialogueContext(IReadOnlyList<DialogueMessage> messages)
    {
        Messages = messages;
    }

    public IReadOnlyList<DialogueMessage> Messages { get; }
}

public sealed class ContextBuilder
{
    public DialogueContext Build(
        NpcPersona persona,
        string sceneState,
        NpcMemory memory,
        DialogueHistory history,
        string newPlayerMessage)
    {
        List<DialogueMessage> messages = new()
        {
            new("system", $"Персона персонажа:\n{persona.ToContextText()}"),
            new("system", $"Текущее состояние сцены: {sceneState}"),
            new("system", $"Память персонажа о текущем игроке:\n{memory.ToContextText()}"),
        };

        messages.AddRange(history.Messages);
        messages.Add(new DialogueMessage("user", newPlayerMessage.Trim()));
        return new DialogueContext(messages);
    }
}
