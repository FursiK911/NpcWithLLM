[CmdletBinding()]
param(
    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\..'),
    [string]$RuntimeDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
if ([string]::IsNullOrWhiteSpace($RuntimeDirectory)) {
    $RuntimeDirectory = Join-Path $SourceRoot 'tools\ollama'
}
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $SourceRoot 'dist'
}
$RuntimeDirectory = (Resolve-Path -LiteralPath $RuntimeDirectory).Path

$projectFile = Join-Path $SourceRoot 'project.godot'
$dotnetProjectFile = Join-Path $SourceRoot 'NpcWithLLM.csproj'
$controllerPath = Join-Path $SourceRoot 'Scripts\Dialogue\OllamaServerController.cs'
$requiredFiles = @(
    $projectFile,
    $dotnetProjectFile,
    $controllerPath,
    (Join-Path $SourceRoot 'README.md'),
    (Join-Path $SourceRoot 'LICENSE'),
    (Join-Path $SourceRoot 'THIRD_PARTY_NOTICES.md'),
    (Join-Path $SourceRoot 'LICENSES\Qwen3.5-9B-Apache-2.0.txt'),
    (Join-Path $SourceRoot 'LICENSES\Ollama-0.32.15-MIT.txt'),
    (Join-Path $SourceRoot 'LICENSES\llama.cpp-b10488-MIT.txt'),
    (Join-Path $SourceRoot 'LICENSES\cpp-httplib-b10488-MIT.txt'),
    (Join-Path $SourceRoot 'LICENSES\jsonhpp-b10488.txt'),
    (Join-Path $SourceRoot 'LICENSES\rotate-bits-b10488.txt'),
    (Join-Path $SourceRoot 'LICENSES\sha256-b10488.txt'),
    (Join-Path $SourceRoot 'LICENSES\xxhash-b10488.txt')
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required project file is missing: '$requiredFile'."
    }
}

$controllerSource = Get-Content -LiteralPath $controllerPath -Raw
$checksumMatch = [regex]::Match($controllerSource, 'BundledOllamaSha256\s*=\s*"([A-Fa-f0-9]{64})"')
if (-not $checksumMatch.Success) {
    throw 'Could not read BundledOllamaSha256 from OllamaServerController.cs.'
}
$expectedExecutableSha256 = $checksumMatch.Groups[1].Value.ToUpperInvariant()
$runtimeExecutable = Join-Path $RuntimeDirectory 'ollama.exe'
$runtimeRunner = Join-Path $RuntimeDirectory 'lib\ollama\llama-server.exe'
if (-not (Test-Path -LiteralPath $runtimeExecutable -PathType Leaf)) {
    throw "Bundled Ollama executable is missing: '$runtimeExecutable'. Restore it from Git LFS or run Restore-OllamaRuntime.ps1."
}
if (-not (Test-Path -LiteralPath $runtimeRunner -PathType Leaf)) {
    throw "Ollama server runner is missing: '$runtimeRunner'. Restore the complete Ollama runtime before packaging."
}

$executableSha256 = (Get-FileHash -LiteralPath $runtimeExecutable -Algorithm SHA256).Hash
if ($executableSha256 -ne $expectedExecutableSha256) {
    throw "Bundled ollama.exe SHA-256 mismatch. Expected $expectedExecutableSha256; got $executableSha256."
}

$forbiddenModelExtensions = @('.gguf', '.ggml', '.safetensors', '.model', '.onnx', '.pt', '.pth', '.bin', '.weights')
$runtimeFiles = @(Get-ChildItem -LiteralPath $RuntimeDirectory -File -Recurse -Force | Sort-Object FullName)
if ($runtimeFiles.Count -eq 0) {
    throw "No runtime files found under '$RuntimeDirectory'."
}
foreach ($file in $runtimeFiles) {
    if ($forbiddenModelExtensions -contains $file.Extension.ToLowerInvariant()) {
        throw "Model-like file found inside the runtime directory; remove it before packaging: '$($file.FullName)'."
    }

    $stream = [System.IO.File]::OpenRead($file.FullName)
    try {
        $prefix = New-Object byte[] 64
        $bytesRead = $stream.Read($prefix, 0, $prefix.Length)
    }
    finally {
        $stream.Dispose()
    }
    if ($bytesRead -gt 0) {
        $header = [System.Text.Encoding]::ASCII.GetString($prefix, 0, $bytesRead)
        if ($header.StartsWith('version https://git-lfs.github.com/spec/v1', [StringComparison]::Ordinal)) {
            throw "Git LFS pointer was not hydrated; restore the runtime file before packaging: '$($file.FullName)'."
        }
    }
}

$excludedDirectories = @(
    '.git', '.godot', '.scratch', '.agents', '.codex', '.qoder', 'graphify-out',
    'bin', 'obj', '.mono', 'dist', 'node_modules', '.ollama'
)
$excludedModelExtensions = $forbiddenModelExtensions + @('.gguf2', '.ggmlv3')
$stagingRoot = Join-Path $env:TEMP "NpcWithLLM-package-$([guid]::NewGuid().ToString('N'))"
$stagedRuntime = Join-Path $stagingRoot 'tools\ollama'
$outputZipName = 'NpcWithLLM-windows-dev.zip'
$temporaryZip = Join-Path $env:TEMP "NpcWithLLM-package-$([guid]::NewGuid().ToString('N')).zip"

try {
    New-Item -ItemType Directory -Path $stagedRuntime -Force | Out-Null

    $directories = New-Object 'System.Collections.Generic.Stack[string]'
    $directories.Push($SourceRoot)
    $sourceFiles = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    while ($directories.Count -gt 0) {
        $currentDirectory = $directories.Pop()
        foreach ($entry in Get-ChildItem -LiteralPath $currentDirectory -Force) {
            $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $entry.FullName)
            if ($entry.PSIsContainer) {
                $relativeDirectory = $relativePath.Replace('\', '/')
                if ($relativeDirectory -eq 'tools/ollama' -or $excludedDirectories -contains $entry.Name) {
                    continue
                }
                $directories.Push($entry.FullName)
                continue
            }

            if ($excludedModelExtensions -contains $entry.Extension.ToLowerInvariant()) {
                continue
            }
            $sourceFiles.Add($entry)
        }
    }

    foreach ($file in ($sourceFiles | Sort-Object FullName)) {
        $relativePath = [System.IO.Path]::GetRelativePath($SourceRoot, $file.FullName)
        $destinationPath = Join-Path $stagingRoot $relativePath
        $destinationParent = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath
    }

    foreach ($file in $runtimeFiles) {
        $relativePath = [System.IO.Path]::GetRelativePath($RuntimeDirectory, $file.FullName)
        $destinationPath = Join-Path $stagedRuntime $relativePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destinationPath
    }

    $manifestLines = foreach ($file in $runtimeFiles) {
        $relativePath = [System.IO.Path]::GetRelativePath($RuntimeDirectory, $file.FullName).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  tools/ollama/$relativePath"
    }
    $manifestPath = Join-Path $stagingRoot 'SHA256SUMS.runtime.txt'
    [System.IO.File]::WriteAllLines($manifestPath, [string[]]$manifestLines, [System.Text.UTF8Encoding]::new($false))

    Add-Type -AssemblyName System.IO.Compression
    $zipStream = [System.IO.File]::Open($temporaryZip, [System.IO.FileMode]::CreateNew)
    try {
        $archive = [System.IO.Compression.ZipArchive]::new(
            $zipStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false,
            [System.Text.Encoding]::UTF8
        )
        try {
            $fixedTimestamp = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
            foreach ($file in (Get-ChildItem -LiteralPath $stagingRoot -File -Recurse | Sort-Object FullName)) {
                $relativePath = [System.IO.Path]::GetRelativePath($stagingRoot, $file.FullName).Replace('\', '/')
                $entryName = "NpcWithLLM/$relativePath"
                $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = $fixedTimestamp
                $inputStream = [System.IO.File]::OpenRead($file.FullName)
                $entryStream = $entry.Open()
                try {
                    $inputStream.CopyTo($entryStream)
                }
                finally {
                    $entryStream.Dispose()
                    $inputStream.Dispose()
                }
            }
        }
        finally {
            $archive.Dispose()
        }
    }
    finally {
        $zipStream.Dispose()
    }

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
    $zipPath = Join-Path $OutputDirectory $outputZipName
    Move-Item -LiteralPath $temporaryZip -Destination $zipPath -Force

    $runtimeManifestPath = Join-Path $OutputDirectory 'NpcWithLLM-windows-dev.runtime.sha256sum'
    Copy-Item -LiteralPath $manifestPath -Destination $runtimeManifestPath -Force
    $zipSha256 = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText(
        "$zipPath.sha256",
        "$zipSha256  $outputZipName`n",
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host "Package: $zipPath"
    Write-Host "Runtime checksums: $runtimeManifestPath"
    Write-Host "Package SHA-256: $zipSha256"
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $temporaryZip) {
        Remove-Item -LiteralPath $temporaryZip -Force
    }
}
