[CmdletBinding()]
param(
    [string]$OutputArchive = 'build/client-delivery/NpcWithLLM-godot-project-final.zip',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$archivePath = if ([System.IO.Path]::IsPathRooted($OutputArchive)) {
    [System.IO.Path]::GetFullPath($OutputArchive)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputArchive))
}
$archiveDirectory = Split-Path -Parent $archivePath
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) "NpcWithLLM-project-$([guid]::NewGuid().ToString('N'))"

function Copy-ProjectFile([string]$RelativePath) {
    $sourcePath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "В исходном проекте не найден обязательный файл: $RelativePath"
    }

    $destinationPath = Join-Path $stageRoot $RelativePath
    $destinationDirectory = Split-Path -Parent $destinationPath
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath
}

function Copy-ProjectTree([string]$RelativePath, [string[]]$Extensions, [string]$ExcludedDirectory = '') {
    $sourceDirectory = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $sourceDirectory -PathType Container)) {
        throw "В исходном проекте не найдена обязательная папка: $RelativePath"
    }

    foreach ($file in Get-ChildItem -LiteralPath $sourceDirectory -Recurse -File) {
        if ($Extensions -notcontains $file.Extension.ToLowerInvariant()) {
            continue
        }
        if ($file.Name -match '\.cs\.uid$') {
            continue
        }
        if ($ExcludedDirectory -and $file.FullName.Contains(
                [System.IO.Path]::DirectorySeparatorChar + $ExcludedDirectory + [System.IO.Path]::DirectorySeparatorChar,
                [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }

        $relativeFilePath = [System.IO.Path]::GetRelativePath($projectRoot, $file.FullName)
        Copy-ProjectFile $relativeFilePath
    }
}

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
New-Item -ItemType Directory -Path $stageRoot | Out-Null

try {
    $rootFiles = @(
        'README.md',
        'CLIENT-README.md',
        'CONTEXT.md',
        'LICENSE',
        'project.godot',
        'Main.tscn',
        'NpcProfile.tres',
        'LocalLlmConfig.tres',
        'icon.svg',
        'icon.svg.import',
        'export_presets.cfg',
        'Build-WindowsPackage.ps1',
        'Package-GodotProject.ps1',
        'Package-WindowsClient.ps1'
    )
    foreach ($relativeFile in $rootFiles) {
        Copy-ProjectFile $relativeFile
    }

    Copy-ProjectTree 'Art' @('.png', '.jpg', '.jpeg', '.webp', '.svg', '.import')
    Copy-ProjectTree 'Scripts' @('.gd', '.uid')
    Copy-ProjectTree 'Tests' @('.gd', '.uid', '.tscn', '.ps1', '.md') 'OptionalModelEvaluation'
    Copy-ProjectTree 'docs/adr' @('.md')
    Copy-ProjectTree 'docs/images' @('.png', '.jpg', '.jpeg', '.webp', '.svg')
    Copy-ProjectTree 'docs/model-evaluation' @('.md')

    $includedFiles = @(Get-ChildItem -LiteralPath $stageRoot -Recurse -File)
    if ($includedFiles.Count -eq 0) {
        throw 'Не удалось собрать файлы Godot-проекта для архива.'
    }
    $unexpectedCode = @($includedFiles | Where-Object {
        $_.Extension -in @('.cs', '.csproj', '.sln')
    })
    if ($unexpectedCode.Count -gt 0) {
        throw 'В архив исходного проекта попали файлы C# или .NET.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stageRoot,
        $archivePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false)

    $archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        foreach ($requiredEntry in @(
                'project.godot',
                'Main.tscn',
                'Scripts/Main.gd',
                'Scripts/Dialogue/LocalLlmResponder.gd',
                'CLIENT-README.md',
                'docs/model-evaluation/qwen3.5-9b-q4km-evaluation.md')) {
            if ($null -eq $archive.GetEntry($requiredEntry)) {
                throw "В архиве отсутствует обязательный файл '$requiredEntry'."
            }
        }
        if (@($archive.Entries | Where-Object { $_.FullName -match '\.(cs|csproj|sln)$' }).Count -gt 0) {
            throw 'Проверка обнаружила C# или .NET-файлы в исходном архиве.'
        }
    }
    finally {
        $archive.Dispose()
    }

    Write-Host "Архив Godot-проекта: $archivePath"
    Write-Host "Файлов в архиве: $($includedFiles.Count)"
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        $resolvedStageRoot = [System.IO.Path]::GetFullPath($stageRoot)
        if (-not $resolvedStageRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Отказ от удаления временной папки вне temp: $resolvedStageRoot"
        }
        Remove-Item -LiteralPath $resolvedStageRoot -Recurse -Force
    }
}
