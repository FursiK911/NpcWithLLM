[CmdletBinding()]
param(
    [string]$ArchivePath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$version = '0.32.15'
$archiveSha256 = 'A1D11D46A944F9C7521F5E9A3A5DB51CD3365401DA627D96C204698FC6914FF9'
$archiveUrl = "https://github.com/ollama/ollama/releases/download/v$version/ollama-windows-amd64.zip"
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$destination = Join-Path $repositoryRoot 'tools\ollama'
$controllerPath = Join-Path $repositoryRoot 'Scripts\Dialogue\OllamaServerController.cs'

if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) {
    throw "Could not find the pinned Ollama checksum in '$controllerPath'."
}

$controllerSource = Get-Content -LiteralPath $controllerPath -Raw
$checksumMatch = [regex]::Match($controllerSource, 'BundledOllamaSha256\s*=\s*"([A-Fa-f0-9]{64})"')
if (-not $checksumMatch.Success) {
    throw 'Could not read BundledOllamaSha256 from OllamaServerController.cs.'
}
$expectedExecutableSha256 = $checksumMatch.Groups[1].Value.ToUpperInvariant()

if ((Test-Path -LiteralPath $destination) -and -not $Force) {
    throw "'$destination' already exists. Use -Force to replace that runtime directory."
}

$temporaryRoot = Join-Path $env:TEMP "NpcWithLLM-Ollama-$([guid]::NewGuid().ToString('N'))"
$downloadedArchive = Join-Path $temporaryRoot 'ollama-windows-amd64.zip'
$extractRoot = Join-Path $temporaryRoot 'extracted'
$backupPath = $null
$destinationInstalled = $false

try {
    New-Item -ItemType Directory -Path $temporaryRoot, $extractRoot -Force | Out-Null

    if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
        Write-Host "Downloading official Ollama v$version Windows AMD64 runtime..."
        $curl = Get-Command 'curl.exe' -ErrorAction SilentlyContinue
        if (-not $curl) {
            throw 'curl.exe is required to stream the large Ollama release archive to disk.'
        }
        & $curl.Source --fail --location --retry 3 --retry-delay 2 --progress-bar --output $downloadedArchive $archiveUrl
        if ($LASTEXITCODE -ne 0) {
            throw "curl.exe failed to download the Ollama release archive (exit code $LASTEXITCODE)."
        }
    }
    else {
        $resolvedArchive = (Resolve-Path -LiteralPath $ArchivePath -PathType Leaf).Path
        Copy-Item -LiteralPath $resolvedArchive -Destination $downloadedArchive
    }

    $actualArchiveSha256 = (Get-FileHash -LiteralPath $downloadedArchive -Algorithm SHA256).Hash
    if ($actualArchiveSha256 -ne $archiveSha256) {
        throw "Ollama archive SHA-256 mismatch. Expected $archiveSha256; got $actualArchiveSha256."
    }

    Expand-Archive -LiteralPath $downloadedArchive -DestinationPath $extractRoot
    $executable = Join-Path $extractRoot 'ollama.exe'
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw 'The official Ollama archive did not contain ollama.exe at its root.'
    }
    $serverRunner = Join-Path $extractRoot 'lib\ollama\llama-server.exe'
    if (-not (Test-Path -LiteralPath $serverRunner -PathType Leaf)) {
        throw 'The official Ollama archive did not contain lib/ollama/llama-server.exe.'
    }

    $actualExecutableSha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash
    if ($actualExecutableSha256 -ne $expectedExecutableSha256) {
        throw "Bundled ollama.exe SHA-256 mismatch. Expected $expectedExecutableSha256; got $actualExecutableSha256."
    }

    if (Test-Path -LiteralPath $destination) {
        $backupPath = "$destination.backup-$([guid]::NewGuid().ToString('N'))"
        Move-Item -LiteralPath $destination -Destination $backupPath
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    $destinationInstalled = $true
    foreach ($entry in Get-ChildItem -LiteralPath $extractRoot -Force) {
        Copy-Item -LiteralPath $entry.FullName -Destination $destination -Recurse -Force
    }

    if ($backupPath -and (Test-Path -LiteralPath $backupPath)) {
        Remove-Item -LiteralPath $backupPath -Recurse -Force
        $backupPath = $null
    }

    Write-Host "Restored Ollama v$version runtime to '$destination'."
    Write-Host "Archive SHA-256: $actualArchiveSha256"
    Write-Host "ollama.exe SHA-256: $actualExecutableSha256"
}
catch {
    if ($destinationInstalled -and (Test-Path -LiteralPath $destination)) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    if ($backupPath -and (Test-Path -LiteralPath $backupPath)) {
        Move-Item -LiteralPath $backupPath -Destination $destination
        $backupPath = $null
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
