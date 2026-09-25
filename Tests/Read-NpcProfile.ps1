# Читает профиль персонажа из res://NpcProfile.tres теми же экспортированными именами свойств,
# которые использует GDScript-ресурс.
function Read-NpcProfile {
    param(
        [string]$Path = (Join-Path $PSScriptRoot '../NpcProfile.tres')
    )

    $required = @(
        'npc_name', 'role', 'player_introduction', 'character', 'speech_style',
        'player_attitude', 'knowledge', 'behavior_constraints', 'situation'
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
        Name               = $values['npc_name']
        Role               = $values['role']
        PlayerIntroduction = $values['player_introduction']
        Character          = $values['character']
        SpeechStyle        = $values['speech_style']
        PlayerAttitude     = $values['player_attitude']
        Knowledge          = $values['knowledge']
        BehaviorConstraints = $values['behavior_constraints']
        Situation          = $values['situation']
    }
}
