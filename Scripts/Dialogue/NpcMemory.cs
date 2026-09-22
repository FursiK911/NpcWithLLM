using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

public sealed class NpcMemory
{
    private static readonly Regex PlayerNamePattern = new(
        @"(?:меня зовут|мо[её] имя)\s+([А-ЯЁA-Z][А-ЯЁA-Zа-яёa-z-]{1,30})",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    private static readonly Regex PlayerProfessionPattern = new(
        @"(?:\bя\b\s+(?:работаю\s+(?:как\s+)?|как\s+)?|моя профессия\s*[—–:-]?\s*)([А-ЯЁA-Z][А-ЯЁA-Zа-яёa-z-]{2,})",
        RegexOptions.IgnoreCase | RegexOptions.CultureInvariant | RegexOptions.Compiled);

    private readonly Dictionary<string, string> _facts = new(StringComparer.OrdinalIgnoreCase);

    public IReadOnlyDictionary<string, string> Facts => _facts;

    public string PlayerName => GetFact("имя игрока");
    public string PlayerProfession => GetFact("профессия игрока");

    public void LearnFrom(string playerMessage)
    {
        if (string.IsNullOrWhiteSpace(playerMessage))
        {
            return;
        }

        Match nameMatch = PlayerNamePattern.Match(playerMessage.Trim());
        if (nameMatch.Success)
        {
            Remember("имя игрока", nameMatch.Groups[1].Value);
        }

        Match professionMatch = PlayerProfessionPattern.Match(playerMessage.Trim());
        if (professionMatch.Success && !IsNonProfessionWord(professionMatch.Groups[1].Value))
        {
            Remember("профессия игрока", professionMatch.Groups[1].Value);
        }
    }

    public string ToContextText()
    {
        if (_facts.Count == 0)
        {
            return "Пока нет сохранённых фактов о игроке.";
        }

        List<string> facts = new();
        foreach ((string key, string value) in _facts)
        {
            facts.Add($"{key}: {value}");
        }

        return string.Join("\n", facts);
    }

    private string GetFact(string key) => _facts.TryGetValue(key, out string value) ? value : null;

    private void Remember(string key, string value)
    {
        _facts[key] = value.Trim().TrimEnd('.', '!', '?', ',');
    }

    private static bool IsNonProfessionWord(string value)
    {
        return value.Equals("устал", StringComparison.OrdinalIgnoreCase) ||
               value.Equals("занят", StringComparison.OrdinalIgnoreCase) ||
               value.Equals("дома", StringComparison.OrdinalIgnoreCase) ||
               value.Equals("готов", StringComparison.OrdinalIgnoreCase);
    }
}
