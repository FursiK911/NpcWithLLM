param(
    [string]$OllamaExecutablePath,
    [switch]$SkipExternalEndpoint
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Этот smoke-сценарий требует PowerShell 7 или новее.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundledPath = Join-Path $projectRoot 'tools/ollama/ollama.exe'
if ([string]::IsNullOrWhiteSpace($OllamaExecutablePath)) {
    if (Test-Path -LiteralPath $bundledPath) {
        $OllamaExecutablePath = $bundledPath
    }
    else {
        $installed = Get-Command ollama.exe -ErrorAction SilentlyContinue
        if ($null -eq $installed) {
            throw "Не найден bundled Ollama по пути '$bundledPath' и ollama.exe отсутствует в PATH."
        }
        $OllamaExecutablePath = $installed.Source
        Write-Host 'Bundled-файл отсутствует; запуск проверяется установленной CLI-версией Ollama.'
    }
}

$exceptionPath = Join-Path $PSScriptRoot '../Scripts/Dialogue/LocalLlmRuntimeException.cs'
$controllerPath = Join-Path $PSScriptRoot '../Scripts/Dialogue/OllamaServerController.cs'
Add-Type -Path @($exceptionPath, $controllerPath)

$checksum = [OllamaServerController]::BundledOllamaSha256
Write-Host "Проверяемая CLI: $OllamaExecutablePath"
Write-Host "Закреплённый SHA-256: $checksum"

if (-not $SkipExternalEndpoint) {
    try {
        Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 | Out-Null
    }
    catch {
        throw 'Для проверки повторного использования сначала запустите внешний Ollama на 127.0.0.1:11434 либо передайте -SkipExternalEndpoint.'
    }

    $external = [OllamaServerController]::new(
        'http://127.0.0.1:11434',
        (Join-Path $projectRoot 'missing-ollama-must-not-launch.exe'))
    try {
        $external.EnsureServerAvailableAsync([System.Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
        if ($external.OwnsProcess) {
            throw 'Контроллер запустил Ollama, хотя внешний endpoint уже отвечал.'
        }
    }
    finally {
        $external.Dispose()
    }
    Write-Host 'PASS: внешний endpoint переиспользован, принадлежащий игре процесс не запускался.'
}

$badChecksum = [OllamaServerController]::new(
    'http://127.0.0.1:0',
    $OllamaExecutablePath,
    ('0' * 64))
try {
    try {
        $badChecksum.EnsureServerAvailableAsync([System.Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
        throw 'Контроллер запустил executable с неверным SHA-256.'
    }
    catch [LocalLlmRuntimeException] {
        if ($_.Exception.Kind -ne [LocalLlmFailureKind]::OllamaExecutableIntegrity) {
            throw
        }
    }
}
finally {
    $badChecksum.Dispose()
}
Write-Host 'PASS: executable с неверным SHA-256 заблокирован до запуска.'

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
$listener.Stop()

$owned = [OllamaServerController]::new(
    "http://127.0.0.1:$port",
    $OllamaExecutablePath)
$ownedProcessId = $null
try {
    $owned.EnsureServerAvailableAsync([System.Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null
    $ownedProcessId = $owned.OwnedProcessId
    if ($null -eq $ownedProcessId) {
        throw 'Контроллер не сохранил владение запущенным процессом Ollama.'
    }

    $process = Get-Process -Id $ownedProcessId
    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        throw 'У процесса Ollama обнаружено видимое главное окно.'
    }
    Write-Host "PASS: собственный Ollama запущен скрыто (PID $ownedProcessId)."
}
finally {
    $owned.Dispose()
}

$deadline = [DateTime]::UtcNow.AddSeconds(5)
while ([DateTime]::UtcNow -lt $deadline -and (Get-Process -Id $ownedProcessId -ErrorAction SilentlyContinue)) {
    Start-Sleep -Milliseconds 100
}
if (Get-Process -Id $ownedProcessId -ErrorAction SilentlyContinue) {
    throw "Собственный процесс Ollama $ownedProcessId остался после завершения контроллера."
}
Write-Host 'PASS: завершён только процесс, запущенный контроллером.'

if (-not $SkipExternalEndpoint) {
    Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 3 | Out-Null
    Write-Host 'PASS: внешний endpoint продолжает отвечать после завершения собственного процесса.'
}
