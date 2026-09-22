Describe 'Dialogue response faults' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'DialogueResponseFault.ps1')
    }

    It 'reports no fault for a mechanically sound answer' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' `
            -Content 'Иван. Я тут механик, а ты зачем пришёл?'
        $faults.Count | Should Be 0
    }

    It 'reports an empty answer' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content '   '
        ($faults -contains 'empty response') | Should Be $true
    }

    It 'reports an answer that only repeats the player message' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' -Content 'Как тебя зовут?'
        ($faults -contains 'copies player message') | Should Be $true
    }

    It 'does not judge the answer by its length' {
        $long = ('слово ' * 55) + 'Иван.'
        $faults = Get-DialogueResponseFault -PlayerMessage 'Как тебя зовут?' -Content $long
        $faults.Count | Should Be 0
    }

    It 'reports an unfinished stream' {
        $faults = Get-DialogueResponseFault -PlayerMessage 'Привет.' -Content 'Привет, я' -Completed $false
        ($faults -contains 'incomplete stream') | Should Be $true
    }
}
