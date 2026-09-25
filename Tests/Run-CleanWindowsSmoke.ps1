[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExecutablePath,
    [string]$ProjectArchivePath = 'build/client-delivery/NpcWithLLM-godot-project-final.zip',
    [string]$WindowsPackageDirectory = 'build/client-delivery/windows-standalone',
    [string]$WindowsArchivePath = 'build/client-delivery/NpcWithLLM-windows-standalone.zip'
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Эта чистая Windows smoke-проверка требует PowerShell 7 или новее.'
}

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$godotPath = (Resolve-Path -LiteralPath $GodotExecutablePath).Path
$godotVersion = (& $godotPath --version | Select-Object -First 1).Trim()
if ($godotVersion -notmatch '^4\.7\.2' -or $godotVersion -match '\.mono\.') {
    throw "Требуется обычный Godot 4.7.2; обнаружен '$godotVersion'."
}

function Resolve-ProjectPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $projectRoot $Path))
}

function Invoke-GdscriptSuite([string]$Root) {
    $runnerPath = Join-Path $Root 'Tests/Run-GdscriptTests.ps1'
    $powerShellPath = Join-Path $PSHOME 'pwsh.exe'
    & $powerShellPath -NoLogo -NoProfile -File $runnerPath -GodotExecutablePath $godotPath
    if ($LASTEXITCODE -ne 0) {
        throw "GDScript-проверки завершились с кодом $LASTEXITCODE в '$Root'."
    }
}

function Assert-NoDotnetArtifacts([string]$Root) {
    $dotnetArtifacts = @(Get-ChildItem -LiteralPath $Root -Recurse -File |
        Where-Object {
            $_.Name -match '^(GodotSharp|GodotSharpEditor|coreclr|hostfxr|hostpolicy|NpcWithLLM)\.dll$' -or
            $_.Name -match '\.(deps|runtimeconfig)\.json$'
        })
    if ($dotnetArtifacts.Count -gt 0) {
        throw "Найдены остатки Godot .NET: $($dotnetArtifacts[0].FullName)"
    }
}

$projectArchive = Resolve-ProjectPath $ProjectArchivePath
$windowsPackageRoot = Resolve-ProjectPath $WindowsPackageDirectory
$windowsArchive = Resolve-ProjectPath $WindowsArchivePath
$requiredPackagePaths = @(
    'NpcWithLLM.exe',
    'README.md',
    'tools/ollama/ollama.exe',
    'tools/ollama/models/manifests'
)
foreach ($requiredPath in $requiredPackagePaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $windowsPackageRoot $requiredPath))) {
        throw "В автономной Windows-поставке отсутствует '$requiredPath'."
    }
}
Assert-NoDotnetArtifacts $windowsPackageRoot

if (-not (Test-Path -LiteralPath $projectArchive -PathType Leaf)) {
    throw "Сначала соберите архив проекта через Package-GodotProject.ps1: $projectArchive"
}
if (-not (Test-Path -LiteralPath $windowsArchive -PathType Leaf)) {
    $windowsPackager = Join-Path $projectRoot 'Package-WindowsClient.ps1'
    & (Join-Path $PSHOME 'pwsh.exe') -NoLogo -NoProfile -File $windowsPackager -PackageDirectory $windowsPackageRoot -OutputArchive $windowsArchive
    if ($LASTEXITCODE -ne 0) {
        throw "Создание ZIP готовой игры завершилось с кодом $LASTEXITCODE."
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "NpcWithLLM-clean-smoke-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$previousGodot = $env:GODOT_EXECUTABLE
$env:GODOT_EXECUTABLE = $godotPath
try {
    Write-Host 'Проверяем GDScript-проект в рабочей копии...'
    Invoke-GdscriptSuite $projectRoot

    if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
        throw 'Для чистой Windows smoke-проверки требуется модуль Pester в PowerShell 7.'
    }
    Push-Location $projectRoot
    try {
        $pesterResult = Invoke-Pester -Path Tests -PassThru -Quiet
    }
    finally {
        Pop-Location
    }
    if ($pesterResult.FailedCount -gt 0) {
        throw "Pester: $($pesterResult.FailedCount) ошибок из $($pesterResult.TotalCount)."
    }

    Add-Type -AssemblyName System.IO.Compression
    $projectZip = [System.IO.Compression.ZipFile]::OpenRead($projectArchive)
    try {
        foreach ($requiredEntry in @(
                'project.godot',
                'Main.tscn',
                'Scripts/Main.gd',
                'Scripts/Dialogue/LocalLlmResponder.gd',
                'Tests/Run-GdscriptTests.ps1',
                'CLIENT-README.md')) {
            if ($null -eq $projectZip.GetEntry($requiredEntry)) {
                throw "В архиве проекта отсутствует '$requiredEntry'."
            }
        }
        if (@($projectZip.Entries | Where-Object { $_.FullName -match '\.(cs|csproj|sln)$' }).Count -gt 0) {
            throw 'В архиве исходного проекта обнаружены C# или .NET-файлы.'
        }
    }
    finally {
        $projectZip.Dispose()
    }

    $windowsZip = [System.IO.Compression.ZipFile]::OpenRead($windowsArchive)
    try {
        foreach ($requiredEntry in @(
                'NpcWithLLM.exe',
                'README.md',
                'tools/ollama/ollama.exe')) {
            if ($null -eq $windowsZip.GetEntry($requiredEntry)) {
                throw "В архиве Windows-поставки отсутствует '$requiredEntry'."
            }
        }
        if (@($windowsZip.Entries | Where-Object {
                    $_.FullName -match '(^|/)(GodotSharp|GodotSharpEditor|coreclr|hostfxr|hostpolicy)\.dll$' -or
                    $_.FullName -match '\.(deps|runtimeconfig)\.json$'
                }).Count -gt 0) {
            throw 'В архив Windows-поставки попали остатки .NET-экспорта.'
        }
    }
    finally {
        $windowsZip.Dispose()
    }

    $unpackedProject = Join-Path $tempRoot 'source'
    Expand-Archive -LiteralPath $projectArchive -DestinationPath $unpackedProject
    Write-Host 'Проверяем исходный архив после распаковки...'
    Invoke-GdscriptSuite $unpackedProject

    Write-Host "PASS: чистая поставка проверена; Godot $godotVersion; Pester $($pesterResult.PassedCount)/$($pesterResult.TotalCount)."
}
finally {
    if ($previousGodot) {
        $env:GODOT_EXECUTABLE = $previousGodot
    }
    else {
        Remove-Item Env:GODOT_EXECUTABLE -ErrorAction SilentlyContinue
    }

    if (Test-Path -LiteralPath $tempRoot) {
        $tempPathPrefix = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        $resolvedTempRoot = [System.IO.Path]::GetFullPath($tempRoot)
        if (-not $resolvedTempRoot.StartsWith($tempPathPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Отказ от удаления временной папки вне temp: $resolvedTempRoot"
        }
        Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
    }
}
