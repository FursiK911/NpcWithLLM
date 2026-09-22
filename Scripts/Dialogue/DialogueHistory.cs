using System;
using System.Collections.Generic;
using System.Linq;

public sealed class DialogueHistory
{
    private readonly int _maxMessages;
    private readonly int _maxCharacters;
    private readonly List<(DialogueMessage Player, DialogueMessage Character)> _pairs = new();

    public DialogueHistory(int maxMessages = 32, int maxCharacters = 8000)
    {
        _maxMessages = maxMessages;
        _maxCharacters = maxCharacters;
    }

    public int MessageCount => _pairs.Count * 2;
    public int CharacterCount => _pairs.Sum(pair => pair.Player.Content.Length + pair.Character.Content.Length);

    public IReadOnlyList<DialogueMessage> Messages
    {
        get
        {
            List<DialogueMessage> messages = new(_pairs.Count * 2);
            foreach ((DialogueMessage player, DialogueMessage character) in _pairs)
            {
                messages.Add(player);
                messages.Add(character);
            }

            return messages;
        }
    }

    public void AddPair(string playerMessage, string characterResponse)
    {
        if (string.IsNullOrWhiteSpace(playerMessage) || string.IsNullOrWhiteSpace(characterResponse))
        {
            return;
        }

        _pairs.Add((new DialogueMessage("user", playerMessage.Trim()), new DialogueMessage("assistant", characterResponse.Trim())));
        TrimToLimits();
    }

    private void TrimToLimits()
    {
        while (_pairs.Count * 2 > _maxMessages || CharacterCount > _maxCharacters)
        {
            _pairs.RemoveAt(0);
        }
    }
}
