Describe 'Npc profile reader' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'Read-NpcProfile.ps1')
    }

    It 'reads the persona fields and the situation from the game profile' {
        $profile = Read-NpcProfile

        $profile.Name | Should Be 'Иван'
        $profile.Role | Should Match 'механик'
        $profile.Knowledge | Should Match 'не знает'
        ($profile.Situation -split "`n`n").Count | Should Be 2
    }

    It 'refuses a profile that lost a field name' {
        $path = Join-Path $TestDrive 'broken.tres'
        Set-Content -LiteralPath $path -Encoding utf8 -Value @'
[gd_resource type="Resource" script_class="NpcProfile" load_steps=2 format=3]

[resource]
name = "Иван"
'@

        $failed = $false
        try { $null = Read-NpcProfile -Path $path }
        catch { $failed = $true; $_.Exception.Message | Should Match 'role' }
        $failed | Should Be $true
    }
}
