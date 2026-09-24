[CmdletBinding()]
param(
    [string]$GodotPath,
    [switch]$LiveModel
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Этот smoke-сценарий требует PowerShell 7 или новее.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testRoot = Join-Path $projectRoot 'Tests'
$packagingScript = Join-Path $projectRoot 'Scripts/Packaging/New-WindowsPackage.ps1'
$lifecycleScript = Join-Path $testRoot 'OllamaLifecycleSmoke.ps1'

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $godotCommand = Get-Command 'Godot_v4.7.2-stable_mono_win64_console.exe' -ErrorAction SilentlyContinue
    if ($null -eq $godotCommand) {
        $godotCommand = Get-Command 'godot_console.exe' -ErrorAction SilentlyContinue
    }
    if ($null -eq $godotCommand) {
        throw 'Передайте путь к Godot .NET console executable через -GodotPath.'
    }
    $GodotPath = $godotCommand.Source
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot executable not found: '$GodotPath'."
}
$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path

function Invoke-CheckedProcess([string]$Name, [string]$Executable, [string[]]$Arguments) {
    Write-Host "`n=== $Name ==="
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name завершился с кодом $LASTEXITCODE."
    }
}

function Invoke-GodotSmoke([string]$Scenario) {
    Invoke-CheckedProcess "Godot: $Scenario" $GodotPath @(
        '--headless', '--path', $projectRoot,
        'Tests/DialogueSmoke.tscn', '--', "--$Scenario")
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw 'Для smoke-проверки требуется .NET SDK.'
}
if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    throw 'Для smoke-проверки требуется модуль Pester.'
}

Push-Location $projectRoot
$temporaryPackageDirectory = Join-Path ([System.IO.Path]::GetTempPath()) `
    "NpcWithLLM-clean-smoke-$([guid]::NewGuid().ToString('N'))"
try {
    Invoke-CheckedProcess 'Сборка C#' 'dotnet' @('build', 'NpcWithLLM.csproj')

    $pesterScripts = @(Get-ChildItem -LiteralPath $testRoot -Filter '*.Tests.ps1' -File |
        Select-Object -ExpandProperty FullName)
    if ($pesterScripts.Count -eq 0) {
        throw "В '$testRoot' не найдены Pester-тесты '*.Tests.ps1'."
    }
    Write-Host "`n=== Pester: $($pesterScripts.Count) файла ==="
    $pesterResult = Invoke-Pester -Script $pesterScripts -PassThru -Quiet
    if ($pesterResult.FailedCount -gt 0) {
        throw "Pester: $($pesterResult.FailedCount) ошибок из $($pesterResult.TotalCount)."
    }
    Write-Host "PASS: Pester $($pesterResult.PassedCount)/$($pesterResult.TotalCount)."

    $externalEndpointReady = $false
    try {
        $endpointResponse = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/api/tags' `
            -SkipHttpErrorCheck -TimeoutSec 3
        $externalEndpointReady = $endpointResponse.StatusCode -eq 200
    }
    catch { }
    $pwshPath = Join-Path $PSHOME 'pwsh.exe'
    $lifecycleArguments = @('-NoLogo', '-NoProfile', '-File', $lifecycleScript)
    if (-not $externalEndpointReady) {
        $lifecycleArguments += '-SkipExternalEndpoint'
        Write-Host 'SKIP: внешний endpoint Ollama сейчас недоступен; проверю bundled-процесс отдельно.'
    }
    Invoke-CheckedProcess 'Жизненный цикл Ollama' $pwshPath $lifecycleArguments

    Invoke-CheckedProcess 'Импорт Godot-ресурсов' $GodotPath @(
        '--headless', '--editor', '--path', $projectRoot, '--import', '--quit')
    Invoke-GodotSmoke 'startup-readiness-only'
    Invoke-GodotSmoke 'startup-failure-only'
    Invoke-GodotSmoke 'local-runtime-failures-only'
    Invoke-GodotSmoke 'dialogue-retry-only'

    New-Item -ItemType Directory -Path $temporaryPackageDirectory | Out-Null
    Invoke-CheckedProcess 'Сборка Windows ZIP' $pwshPath @(
        '-NoLogo', '-NoProfile', '-File', $packagingScript,
        '-OutputDirectory', $temporaryPackageDirectory)

    $packagePath = Join-Path $temporaryPackageDirectory 'NpcWithLLM-windows-dev.zip'
    $runtimeManifestPath = Join-Path $temporaryPackageDirectory 'NpcWithLLM-windows-dev.runtime.sha256sum'
    if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $runtimeManifestPath -PathType Leaf)) {
        throw 'Сборщик не создал ZIP и manifest runtime.'
    }
    $packageSha256 = (Get-FileHash -LiteralPath $packagePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecar = (Get-Content -LiteralPath "$packagePath.sha256" -Raw).Trim()
    if (-not $sidecar.StartsWith("$packageSha256  ", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'SHA-256 sidecar Windows ZIP не совпадает с архивом.'
    }

    Add-Type -AssemblyName System.IO.Compression
    $archive = [System.IO.Compression.ZipFile]::OpenRead($packagePath)
    try {
        $requiredEntries = @(
            'NpcWithLLM/Main.tscn',
            'NpcWithLLM/LocalLlmConfig.tres',
            'NpcWithLLM/tools/ollama/ollama.exe',
            'NpcWithLLM/tools/ollama/lib/ollama/llama-server.exe',
            'NpcWithLLM/SHA256SUMS.runtime.txt'
        )
        foreach ($requiredEntry in $requiredEntries) {
            if ($null -eq $archive.GetEntry($requiredEntry)) {
                throw "В ZIP отсутствует обязательный файл '$requiredEntry'."
            }
        }

        $manifestLines = @(Get-Content -LiteralPath $runtimeManifestPath)
        if ($manifestLines.Count -eq 0) {
            throw 'Manifest runtime пуст.'
        }
        foreach ($line in $manifestLines) {
            $match = [regex]::Match($line, '^([A-Fa-f0-9]{64})\s{2}(.+)$')
            if (-not $match.Success) {
                throw "Некорректная строка manifest: '$line'."
            }
            $entry = $archive.GetEntry("NpcWithLLM/$($match.Groups[2].Value)")
            if ($null -eq $entry) {
                throw "В ZIP отсутствует runtime-файл '$($match.Groups[2].Value)'."
            }
            $stream = $entry.Open()
            try { $actualHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)) }
            finally { $stream.Dispose() }
            if ($actualHash -ne $match.Groups[1].Value) {
                throw "Checksum runtime-файла '$($entry.FullName)' не совпал с manifest."
            }
        }

        $modelExtensions = @('.gguf', '.ggml', '.safetensors', '.model', '.onnx', '.weights')
        foreach ($entry in $archive.Entries) {
            if ($modelExtensions -contains [System.IO.Path]::GetExtension($entry.FullName).ToLowerInvariant()) {
                throw "В ZIP попали веса модели: '$($entry.FullName)'."
            }
        }
    }
    finally { $archive.Dispose() }
    Write-Host "PASS: ZIP, sidecar и $($manifestLines.Count) checksum runtime проверены; весов модели нет."

    $unpackedProject = Join-Path $temporaryPackageDirectory 'unpacked'
    Expand-Archive -LiteralPath $packagePath -DestinationPath $unpackedProject
    $unpackedProject = Join-Path $unpackedProject 'NpcWithLLM'
    Invoke-CheckedProcess 'Сборка распакованного ZIP' 'dotnet' @(
        'build', (Join-Path $unpackedProject 'NpcWithLLM.csproj'))
    Invoke-CheckedProcess 'Импорт распакованного ZIP' $GodotPath @(
        '--headless', '--editor', '--path', $unpackedProject, '--import', '--quit')

    Write-Host "`n=== Запуск проекта из ZIP без редактора Godot ==="
    $gameOutput = & $GodotPath --headless --path $unpackedProject --quit-after 120 2>&1
    $gameExitCode = $LASTEXITCODE
    $gameOutput | ForEach-Object { Write-Host $_ }
    if ($gameExitCode -ne 0) {
        throw "Запуск проекта из ZIP завершился с кодом $gameExitCode."
    }
    if (($gameOutput -join "`n") -match 'ERROR:|Failed loading resource') {
        throw 'Запуск проекта из ZIP вывел ошибку Godot.'
    }
    Write-Host 'PASS: распакованный проект стартовал без режима редактора.'

    if ($LiveModel) {
        Write-Host "`n=== Live-диалог из распакованного ZIP ==="
        Invoke-CheckedProcess 'Live-модель в распакованном ZIP' $GodotPath @(
            '--headless', '--path', $unpackedProject,
            'Tests/DialogueSmoke.tscn', '--', '--real-dialogue-only')
    }
    else {
        Write-Host 'SKIP: реальный диалог и память имени/профессии требуют установленной модели; используйте -LiveModel.'
    }
}
finally {
    Pop-Location
    if (Test-Path -LiteralPath $temporaryPackageDirectory) {
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        $resolvedTemporaryDirectory = (Resolve-Path -LiteralPath $temporaryPackageDirectory).Path
        if (-not $resolvedTemporaryDirectory.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove path outside the temp directory: '$resolvedTemporaryDirectory'."
        }
        Remove-Item -LiteralPath $resolvedTemporaryDirectory -Recurse -Force
    }
}

Write-Host "`nPASS: Windows smoke-проверки завершены. Godot: $GodotPath"
