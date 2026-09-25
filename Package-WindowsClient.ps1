[CmdletBinding()]
param(
    [string]$PackageDirectory = 'build/client-delivery/windows-standalone',
    [string]$OutputArchive = 'build/client-delivery/NpcWithLLM-windows-standalone.zip',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$packageRoot = if ([System.IO.Path]::IsPathRooted($PackageDirectory)) {
    [System.IO.Path]::GetFullPath($PackageDirectory)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $PackageDirectory))
}
$archivePath = if ([System.IO.Path]::IsPathRooted($OutputArchive)) {
    [System.IO.Path]::GetFullPath($OutputArchive)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputArchive))
}

foreach ($requiredPath in @(
        'NpcWithLLM.exe',
        'README.md',
        'tools/ollama/ollama.exe',
        'tools/ollama/models/manifests')) {
    if (-not (Test-Path -LiteralPath (Join-Path $packageRoot $requiredPath))) {
        throw "В Windows-пакете отсутствует '$requiredPath': $packageRoot"
    }
}

$dotnetArtifacts = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File |
    Where-Object {
        $_.Name -match '^(GodotSharp|GodotSharpEditor|coreclr|hostfxr|hostpolicy|NpcWithLLM)\.dll$' -or
        $_.Name -match '\.(deps|runtimeconfig)\.json$'
    })
if ($dotnetArtifacts.Count -gt 0) {
    throw "Windows-пакет содержит остатки Godot .NET экспорта: $($dotnetArtifacts[0].FullName)"
}

$archiveDirectory = Split-Path -Parent $archivePath
New-Item -ItemType Directory -Path $archiveDirectory -Force | Out-Null
if (Test-Path -LiteralPath $archivePath) {
    if (-not $Force) {
        throw "Архив уже существует; передайте -Force только для пересборки файла внутри build: $archivePath"
    }
    $buildRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'build'))
    $buildPrefix = $buildRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $archivePath.StartsWith($buildPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Отказ от перезаписи архива вне build: $archivePath"
    }
    Remove-Item -LiteralPath $archivePath -Force
}

$files = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File)
if ($files.Count -eq 0) {
    throw "В Windows-пакете нет файлов для архивирования: $packageRoot"
}

Add-Type -AssemblyName System.IO.Compression
$fileStream = [System.IO.File]::Open(
    $archivePath,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None)
$archive = [System.IO.Compression.ZipArchive]::new(
    $fileStream,
    [System.IO.Compression.ZipArchiveMode]::Create,
    $false)
$expectedUncompressedBytes = [long]0
try {
    $buffer = [byte[]]::new(1MB)
    foreach ($file in $files) {
        $entryName = [System.IO.Path]::GetRelativePath($packageRoot, $file.FullName).Replace('\', '/')
        $entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::NoCompression)
        $inputStream = [System.IO.File]::OpenRead($file.FullName)
        $entryStream = $entry.Open()
        try {
            $inputStream.CopyTo($entryStream, $buffer.Length)
        }
        finally {
            $entryStream.Dispose()
            $inputStream.Dispose()
        }
        $expectedUncompressedBytes += $file.Length
    }
}
finally {
    $archive.Dispose()
    $fileStream.Dispose()
}

$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
    $entries = @($archive.Entries)
    if ($entries.Count -ne $files.Count) {
        throw "В ZIP $($entries.Count) файлов, ожидалось $($files.Count)."
    }
    $archivedUncompressedBytes = [long]0
    foreach ($entry in $entries) {
        $archivedUncompressedBytes += $entry.Length
    }
    if ($archivedUncompressedBytes -ne $expectedUncompressedBytes) {
        throw "Суммарный размер файлов в ZIP ($archivedUncompressedBytes) не совпадает с исходным ($expectedUncompressedBytes)."
    }
    foreach ($requiredEntry in @(
            'NpcWithLLM.exe',
            'README.md',
            'tools/ollama/ollama.exe')) {
        if ($null -eq $archive.GetEntry($requiredEntry)) {
            throw "В готовом ZIP отсутствует обязательный файл '$requiredEntry'."
        }
    }
}
finally {
    $archive.Dispose()
}

$archiveInfo = Get-Item -LiteralPath $archivePath
Write-Host "Архив готовой Windows-игры: $archivePath"
Write-Host "Файлов: $($files.Count); размер: $([Math]::Round($archiveInfo.Length / 1GB, 2)) ГБ"
