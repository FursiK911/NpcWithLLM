using System;

public sealed class NpcPersona
{
    public NpcPersona(
        string name,
        string role,
        string character,
        string speechStyle,
        string playerAttitude,
        string knowledge,
        string behaviorConstraints)
    {
        Name = Require(name, nameof(name));
        Role = Require(role, nameof(role));
        Character = Require(character, nameof(character));
        SpeechStyle = Require(speechStyle, nameof(speechStyle));
        PlayerAttitude = Require(playerAttitude, nameof(playerAttitude));
        Knowledge = Require(knowledge, nameof(knowledge));
        BehaviorConstraints = Require(behaviorConstraints, nameof(behaviorConstraints));
    }

    public string Name { get; }
    public string Role { get; }
    public string Character { get; }
    public string SpeechStyle { get; }
    public string PlayerAttitude { get; }
    public string Knowledge { get; }
    public string BehaviorConstraints { get; }

    public string ToContextText()
    {
        return $"Имя: {Name}\n" +
               $"Роль: {Role}\n" +
               $"Характер: {Character}\n" +
               $"Стиль речи: {SpeechStyle}\n" +
               $"Отношение к игроку: {PlayerAttitude}\n" +
               $"Что знает и чего не знает: {Knowledge}\n" +
               $"Ограничения поведения: {BehaviorConstraints}";
    }

    private static string Require(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Значение не может быть пустым.", parameterName);
        }

        return value.Trim();
    }
}
