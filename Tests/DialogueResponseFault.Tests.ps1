Describe 'Dialogue response faults' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'DialogueResponseFault.ps1')
    }

    It 'reports no fault for a mechanically sound answer' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' `
            -Content 'Иван. Я тут механик, а ты зачем пришёл?' -FirstTextMs 120
        $faults.Count | Should Be 0
    }

    It 'reports an empty answer' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content '   ' -FirstTextMs 130
        ($faults -contains 'empty response') | Should Be $true
    }

    It 'reports an answer that only repeats the player message' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' -Content 'Как тебя зовут?' -FirstTextMs 140
        ($faults -contains 'copies player message') | Should Be $true
    }

    It 'reports an answer longer than fifty words' {
        $long = ('слово ' * 55) + 'Иван.'
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' -Content $long -FirstTextMs 150
        ($faults -join ',') | Should Match 'too long'
    }

    It 'reports an answer that stays under the word limit' {
        $short = ('слово ' * 49) + 'Иван.'
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' -Content $short -FirstTextMs 160
        ($faults -join ',') | Should Not Match 'too long'
    }

    It 'reports a first visible text that arrives too late' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content 'Привет, я Иван.' -FirstTextMs 5200
        ($faults -contains 'first text >= 5 seconds or missing') | Should Be $true
    }

    It 'reports a first visible text that never arrived' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content 'Привет, я Иван.' -FirstTextMs $null
        ($faults -contains 'first text >= 5 seconds or missing') | Should Be $true
    }

    It 'accepts a first visible text under five seconds' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content 'Привет, я Иван.' -FirstTextMs 4999
        ($faults -contains 'first text >= 5 seconds or missing') | Should Be $false
    }

    It 'reports an unfinished stream' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content 'Привет, я' -FirstTextMs 170 -Completed $false
        ($faults -contains 'incomplete stream') | Should Be $true
    }
}
