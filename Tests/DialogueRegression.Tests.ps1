Describe 'Dialogue regression' {
    BeforeAll {
        Add-Type -Path @(
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\DialogueMessage.cs'),
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\LocalLlmRequest.cs'),
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\DialogueHistory.cs'),
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\NpcMemory.cs'),
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\NpcPersona.cs'),
            (Join-Path $PSScriptRoot '..\Scripts\Dialogue\ContextBuilder.cs')
        )

        $script:persona = [NpcPersona]::new(
            'Иван',
            'механик в мастерской',
            'наблюдательный и практичный',
            'короткие фразы',
            'настороженно, но разговаривает',
            'знает мастерскую; не знает, кто вошедший',
            'не выдумывает факты')
    }

    It 'sends system context as a chat message before the player message' {
        $context = [DialogueMessage[]] @(
            [DialogueMessage]::new('system', 'Память персонажа: имя игрока: Дмитрий'),
            [DialogueMessage]::new('user', 'Как меня зовут?')
        )

        $payload = [LocalLlmRequestBuilder]::Create('qwen3.5:0.8b', $context, 0.7, 0.9, 256)

        $payload.Messages.Count | Should Be 2
        $payload.Messages[0].Role | Should Be 'system'
        $payload.Messages[0].Content | Should Be 'Память персонажа: имя игрока: Дмитрий'
        $payload.Messages[1].Role | Should Be 'user'
        $payload.Messages[1].Content | Should Be 'Как меня зовут?'
        $payload.Model | Should Be 'qwen3.5:0.8b'
        $payload.Think | Should Be $false
    }

    It 'serializes Ollama generation options with Ollama field names' {
        $context = [DialogueMessage[]] @(
            [DialogueMessage]::new('system', 'Ты — Иван, механик.'),
            [DialogueMessage]::new('user', 'Привет.')
        )

        $payload = [LocalLlmRequestBuilder]::Create('qwen3.5:4b', $context, 0.2, 0.9, 64)
        $jsonOptions = [System.Text.Json.JsonSerializerOptions]::new()
        $jsonOptions.PropertyNamingPolicy = [System.Text.Json.JsonNamingPolicy]::CamelCase
        $json = [System.Text.Json.JsonSerializer]::Serialize($payload, $jsonOptions)

        $json | Should Match '"top_p"'
        $json | Should Match '"num_predict"'
        $json | Should Not Match '"topP"'
        $json | Should Not Match '"maxTokens"'
    }

    It 'includes remembered player facts in an explicit fact question' {
        $memory = [NpcMemory]::new()
        $memory.LearnFrom('Меня зовут Дмитрий.')
        $memory.LearnFrom('Я работаю программистом.')

        $persona = [NpcPersona]::new(
            'Иван',
            'спокойный механик из мастерской',
            'наблюдательный и практичный',
            'коротко и спокойно',
            'сдержанное любопытство',
            'знает мастерскую и инструменты; не знает, кто вошедший',
            'не выдумывай факты')

        $context = [ContextBuilder]::new().Build(
            $persona,
            'персонаж думает',
            $memory,
            [DialogueHistory]::new(),
            'Как меня зовут и кем я работаю?')

        $lastMessage = $context.Messages[$context.Messages.Count - 1].Content
        $lastMessage | Should Be 'Как меня зовут и кем я работаю?'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'имя игрока: Дмитрий'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'профессия игрока: программистом'
    }

    It 'includes NPC identity in an explicit identity question' {
        $persona = [NpcPersona]::new(
            'Иван',
            'спокойный механик из мастерской',
            'наблюдательный и практичный',
            'коротко и спокойно',
            'сдержанное любопытство',
            'знает мастерскую и инструменты; не знает, кто вошедший',
            'не выдумывай факты')

        $context = [ContextBuilder]::new().Build(
            $persona,
            'готов к диалогу',
            [NpcMemory]::new(),
            [DialogueHistory]::new(),
            'А ты кто?')

        $lastMessage = $context.Messages[$context.Messages.Count - 1].Content
        $lastMessage | Should Be 'А ты кто?'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'Имя: Иван'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'Роль: спокойный механик из мастерской'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'Ты — Иван'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Not Match 'Ответь от имени персонажа в формате'
    }

    It 'keeps ordinary dialogue unchanged' {
        $persona = [NpcPersona]::new(
            'Иван',
            'спокойный механик из мастерской',
            'наблюдательный и практичный',
            'коротко и спокойно',
            'сдержанное любопытство',
            'знает мастерскую и инструменты; не знает, кто вошедший',
            'не выдумывай факты')

        $context = [ContextBuilder]::new().Build(
            $persona,
            'готов к диалогу',
            [NpcMemory]::new(),
            [DialogueHistory]::new(),
            'Рад познакомиться.')

        $lastMessage = $context.Messages[$context.Messages.Count - 1].Content
        $lastMessage | Should Be 'Рад познакомиться.'
    }

    It 'recognizes a greeting with a player name and an NPC name question' {
        $persona = [NpcPersona]::new(
            'Иван',
            'спокойный механик из мастерской',
            'наблюдательный и практичный',
            'коротко и спокойно',
            'сдержанное любопытство',
            'знает мастерскую и инструменты; не знает, кто вошедший',
            'не выдумывай факты')

        $context = [ContextBuilder]::new().Build(
            $persona,
            'готов к диалогу',
            [NpcMemory]::new(),
            [DialogueHistory]::new(),
            'Привет, я Дмитрий. А тебя как зовут?')

        $lastMessage = $context.Messages[$context.Messages.Count - 1].Content
        $lastMessage | Should Be 'Привет, я Дмитрий. А тебя как зовут?'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'Имя: Иван'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Match 'Роль: спокойный механик из мастерской'
        ($context.Messages | ForEach-Object { $_.Content } | Out-String) |
            Should Not Match 'Ответь от имени персонажа в формате'
    }

    It 'does not learn an ordinary sentence as a profession' {
        $memory = [NpcMemory]::new()
        $memory.LearnFrom('Я впервые в этом городе.')
        $memory.PlayerProfession | Should BeNullOrEmpty
        $memory.LearnFrom('Я работаю программистом.')
        $memory.PlayerProfession | Should Be 'программистом'
        $memory.LearnFrom('Я слышал странный стук.')
        $memory.PlayerProfession | Should Be 'программистом'
    }

    It 'states what the character knows and does not know' {
        $persona = [NpcPersona]::new(
            'Иван',
            'механик; сам принимает машины в ремонт в своей мастерской',
            'недоверчивый, наблюдательный и практичный',
            'короткие спокойные фразы, по делу',
            'незнакомца встречает настороженно',
            'знает мастерскую и машину в ремзоне; не знает, кто вошедший',
            'не выдумывает факты о мире')

        $context = [ContextBuilder]::new().Build(
            $persona,
            'Иван в мастерской.',
            [NpcMemory]::new(),
            [DialogueHistory]::new(),
            'Кто ты?')

        ($context.Messages[0].Content) |
            Should Match 'Что знает и чего не знает: знает мастерскую и машину в ремзоне'
    }

    It 'asks for the language the visitor wrote in' {
        $context = [ContextBuilder]::new().Build(
            $persona, 'Иван в мастерской.', [NpcMemory]::new(), [DialogueHistory]::new(), 'Привет.')

        ($context.Messages[0].Content) | Should Match 'Reply in the language the visitor'
        ($context.Messages[0].Content) | Should Not Match 'natural Russian conversation'
    }

    It 'keeps generic character traits out of the instructions' {
        $context = [ContextBuilder]::new().Build(
            $persona, 'Иван в мастерской.', [NpcMemory]::new(), [DialogueHistory]::new(), 'Привет.')

        ($context.Messages[0].Content) | Should Not Match 'The character is an ordinary person'
        ($context.Messages[0].Content) | Should Not Match 'A mechanic can talk about life'
        ($context.Messages[0].Content) | Should Match 'not a service function'
    }

    It 'lets the character revise a guess about the visitor' {
        $context = [ContextBuilder]::new().Build(
            $persona, 'Иван в мастерской.', [NpcMemory]::new(), [DialogueHistory]::new(), 'Привет.')

        ($context.Messages[0].Content) | Should Match 'guess is his own opinion'
    }

    It 'keeps the newest 32 messages and drops whole old pairs' {
        $history = [DialogueHistory]::new()
        1..25 | ForEach-Object { $history.AddPair("ход $_", "ответ $_") }

        $history.MessageCount | Should Be 32
        $history.Messages[0].Content | Should Be 'ход 10'
        $history.Messages[31].Content | Should Be 'ответ 25'
    }

    It 'honours limits passed in' {
        $byMessages = [DialogueHistory]::new(4, 8000)
        1..5 | ForEach-Object { $byMessages.AddPair("ход $_", "ответ $_") }
        $byMessages.MessageCount | Should Be 4
        $byMessages.Messages[0].Content | Should Be 'ход 4'

        $byCharacters = [DialogueHistory]::new(32, 40)
        $long = 'с' * 30
        1..4 | ForEach-Object { $byCharacters.AddPair($long, $long) }
        ($byCharacters.CharacterCount -le 40) | Should Be $true
    }
}
