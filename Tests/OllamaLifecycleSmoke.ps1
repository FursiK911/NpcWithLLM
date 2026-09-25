param(
    [string]$GodotExecutablePath = $env:GODOT_EXECUTABLE,
    [string]$OllamaExecutablePath = '',
    [string]$OllamaModelsDirectory = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($GodotExecutablePath)) {
    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($null -eq $godotCommand) {
        throw 'Укажите стандартный Godot 4.x через -GodotExecutablePath или переменную GODOT_EXECUTABLE.'
    }
    $GodotExecutablePath = $godotCommand.Source
}

$godotPath = (Resolve-Path -LiteralPath $GodotExecutablePath).Path

Remove-Item Env:NPC_OLLAMA_SMOKE_EXECUTABLE -ErrorAction SilentlyContinue
Remove-Item Env:NPC_OLLAMA_SMOKE_MODELS -ErrorAction SilentlyContinue
Remove-Item Env:NPC_OLLAMA_SMOKE_PORT -ErrorAction SilentlyContinue
if (-not [string]::IsNullOrWhiteSpace($OllamaExecutablePath)) {
    $OllamaExecutablePath = (Resolve-Path -LiteralPath $OllamaExecutablePath).Path
    if ([string]::IsNullOrWhiteSpace($OllamaModelsDirectory)) {
        $OllamaModelsDirectory = Join-Path (Split-Path -Parent $OllamaExecutablePath) 'models'
    }
    $OllamaModelsDirectory = (Resolve-Path -LiteralPath $OllamaModelsDirectory).Path

    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        $env:NPC_OLLAMA_SMOKE_PORT = [string]$listener.LocalEndpoint.Port
    }
    finally {
        $listener.Stop()
    }
    $env:NPC_OLLAMA_SMOKE_EXECUTABLE = $OllamaExecutablePath
    $env:NPC_OLLAMA_SMOKE_MODELS = $OllamaModelsDirectory
}

$output = @(& $godotPath --headless --path $projectRoot --script res://Tests/OllamaLifecycleSmoke.gd 2>&1)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }
if ($exitCode -ne 0 -or ($output -join "`n") -notmatch 'PASS: Ollama lifecycle smoke') {
    throw "Проверка lifecycle Ollama в Godot завершилась с кодом $exitCode."
}
