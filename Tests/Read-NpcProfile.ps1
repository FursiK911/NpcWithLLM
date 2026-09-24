# Читает профиль персонажа из res://NpcProfile.tres, чтобы харнесс оценивал ту же роль,
# что и игра. Ключи блока [resource] совпадают с именами C#-свойств (Name, Role, …): Godot 4.7
# не приводит их к нижнему регистру, и ключ «name» был бы проигнорирован молча.
function Read-NpcProfile {
    param(
        [string]$Path = (Join-Path $PSScriptRoot '../NpcProfile.tres')
    )

    $required = @(
        'Name', 'Role', 'PlayerIntroduction', 'Character', 'SpeechStyle',
        'PlayerAttitude', 'Knowledge', 'BehaviorConstraints', 'Situation'
    )
    $values = @{}

    foreach ($line in ((Get-Content -LiteralPath $Path -Raw -Encoding utf8) -split "`r?`n")) {
        if ($line -match '^([A-Za-z][A-Za-z0-9_]*) = "(.*)"$') {
            $values[$Matches[1]] = $Matches[2].Replace('\"', '"').Replace('\n', "`n").Replace('\t', "`t")
        }
    }

    $missing = @($required | Where-Object { [string]::IsNullOrWhiteSpace($values[$_]) })
    if ($missing.Count -gt 0) {
        throw "Профиль ${Path}: не читаются поля $($missing -join ', '). Проверьте имена ключей в блоке [resource]."
    }

    [pscustomobject]@{
        Name               = $values['Name']
        Role               = $values['Role']
        PlayerIntroduction = $values['PlayerIntroduction']
        Character          = $values['Character']
        SpeechStyle        = $values['SpeechStyle']
        PlayerAttitude     = $values['PlayerAttitude']
        Knowledge          = $values['Knowledge']
        BehaviorConstraints = $values['BehaviorConstraints']
        Situation          = $values['Situation']
    }
}
