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
}
