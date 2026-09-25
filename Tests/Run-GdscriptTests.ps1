param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExecutablePath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotPath = (Resolve-Path -LiteralPath $GodotExecutablePath).Path

function Invoke-GodotCheck {
    param(
        [string[]]$Arguments,
        [string]$SuccessMarker = ''
    )

    $output = @(& $godotPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    $joined = $output -join "`n"
    if ($exitCode -ne 0 -or $joined.Contains('SCRIPT ERROR:') -or $joined.Contains('ERROR:')) {
        throw "Godot завершился с кодом $exitCode или сообщил об ошибке: $($Arguments -join ' ')"
    }
    if ($SuccessMarker -and $joined -notmatch [regex]::Escape($SuccessMarker)) {
        throw "Godot не вывел отметку '$SuccessMarker': $($Arguments -join ' ')"
    }
}

$version = (& $godotPath --version | Select-Object -First 1).Trim()
if ($version -notmatch '^4\.') {
    throw "Требуется Godot 4.x; обнаружен '$version'."
}

Write-Host "Проверяем GDScript в Godot $version..."
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--editor', '--quit')
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://Tests/GdscriptRegression.gd') -SuccessMarker 'PASS: GDScript regression checks'
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, 'res://Tests/DialogueSmoke.tscn') -SuccessMarker 'PASS: DialogueSmoke'
Invoke-GodotCheck -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://Tests/OllamaLifecycleSmoke.gd') -SuccessMarker 'PASS: Ollama lifecycle smoke'

Write-Host 'Все GDScript-проверки завершились успешно.'
