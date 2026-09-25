param(
    [Parameter(Mandatory = $true)]
    [string]$GodotExecutablePath,
    [string]$OllamaInstallDirectory = (Join-Path $env:LOCALAPPDATA 'Programs/Ollama'),
    [string]$OllamaModelsDirectory = (Join-Path $env:USERPROFILE '.ollama/models'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'build/client-delivery/windows-standalone')
)

$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$godotPath = (Resolve-Path -LiteralPath $GodotExecutablePath).Path
$ollamaRoot = (Resolve-Path -LiteralPath $OllamaInstallDirectory).Path
$modelsRoot = (Resolve-Path -LiteralPath $OllamaModelsDirectory).Path
$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDirectory))
}
$ollamaHash = '0A9D42EABC59FDAFDE8D2D3E7964F6050B31A17B3E3795BFACB367C12DF790F4'

if (-not (Test-Path -LiteralPath (Join-Path $ollamaRoot 'ollama.exe'))) {
    throw "В каталоге runtime не найден ollama.exe: $ollamaRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $ollamaRoot 'lib'))) {
    throw "В каталоге runtime не найдена папка lib: $ollamaRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'export_presets.cfg'))) {
    throw 'В проекте отсутствует export_presets.cfg.'
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'Scripts/Main.gd'))) {
    throw 'В проекте отсутствует GDScript-точка входа Scripts/Main.gd.'
}
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'CLIENT-README.md'))) {
    throw 'В проекте отсутствует CLIENT-README.md для поставляемого пакета.'
}
$projectSettings = Get-Content -LiteralPath (Join-Path $projectRoot 'project.godot') -Raw
if ($projectSettings.Contains('"C#"') -or $projectSettings -match '(?im)^\[dotnet\]') {
    throw 'project.godot всё ещё объявляет зависимость от Godot .NET.'
}
if (Test-Path -LiteralPath $outputRoot) {
    $dotnetArtifacts = @(Get-ChildItem -LiteralPath $outputRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match '^(GodotSharp|GodotSharpEditor|coreclr|hostfxr|hostpolicy|NpcWithLLM)\.dll$' -or
            $_.Name -match '\.(deps|runtimeconfig)\.json$'
        })
    if ($dotnetArtifacts.Count -gt 0) {
        throw "Каталог результата содержит остатки Godot .NET экспорта. Выберите чистую папку: $outputRoot"
    }

    $existingItems = @(Get-ChildItem -LiteralPath $outputRoot -Force)
    $hasExistingPackage = (Test-Path -LiteralPath (Join-Path $outputRoot 'NpcWithLLM.exe')) -and
        (Test-Path -LiteralPath (Join-Path $outputRoot 'tools/ollama/ollama.exe')) -and
        (Test-Path -LiteralPath (Join-Path $outputRoot 'tools/ollama/models/manifests'))
    if ($existingItems.Count -gt 0 -and -not $hasExistingPackage) {
        throw "Каталог результата уже занят или содержит неполный пакет: $outputRoot. Укажите новый путь вывода."
    }
}

$actualOllamaHash = (Get-FileHash -LiteralPath (Join-Path $ollamaRoot 'ollama.exe') -Algorithm SHA256).Hash
if ($actualOllamaHash -ne $ollamaHash) {
    throw "Версия Ollama не совпала с проверенной 0.32.15. Ожидался SHA-256 $ollamaHash; получен $actualOllamaHash."
}

$configText = Get-Content -LiteralPath (Join-Path $projectRoot 'LocalLlmConfig.tres') -Raw
$modelMatch = [regex]::Match($configText, '(?m)^model_name\s*=\s*"([^"\r\n]+)"')
if (-not $modelMatch.Success) {
    throw 'Не удалось прочитать model_name из LocalLlmConfig.tres.'
}
$modelName = $modelMatch.Groups[1].Value
$modelParts = $modelName.Split(':', 2)
$modelPath = $modelParts[0]
$modelTag = if ($modelParts.Length -eq 2) { $modelParts[1] } else { 'latest' }
$registryPath = if ($modelPath.Contains('/')) {
    Join-Path 'registry.ollama.ai' $modelPath
}
else {
    Join-Path 'registry.ollama.ai/library' $modelPath
}
$manifestPath = Join-Path $modelsRoot (Join-Path 'manifests' (Join-Path $registryPath $modelTag))
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Модель '$modelName' отсутствует в источнике '$modelsRoot'."
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$layers = @($manifest.config) + @($manifest.layers)
foreach ($layer in $layers) {
    $blobName = $layer.digest.Replace(':', '-')
    $blobPath = Join-Path $modelsRoot (Join-Path 'blobs' $blobName)
    if (-not (Test-Path -LiteralPath $blobPath)) {
        throw "В model store отсутствует слой $($layer.digest)."
    }
    if ((Get-Item -LiteralPath $blobPath).Length -ne [long]$layer.size) {
        throw "Размер слоя $($layer.digest) не совпадает с manifest модели '$modelName'."
    }
    $blobHash = (Get-FileHash -LiteralPath $blobPath -Algorithm SHA256).Hash
    if ($blobHash -ne $layer.digest.Substring(7)) {
        throw "SHA-256 слоя $($layer.digest) не совпадает с manifest модели '$modelName'."
    }
}

$godotVersion = (& $godotPath --version | Select-Object -First 1).Trim()
if ($godotVersion -notmatch '^4\.7\.2' -or $godotVersion -match '\.mono\.') {
    throw "Требуется обычный Godot 4.7.2 без .NET; обнаружен '$godotVersion'."
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$gameExecutable = Join-Path $outputRoot 'NpcWithLLM.exe'
$runtimeDestination = Join-Path $outputRoot 'tools/ollama'

Push-Location $projectRoot
try {
    Write-Host 'Импорт проекта Godot...'
    $editorOutput = & $godotPath --headless --path $projectRoot --editor --quit 2>&1
    $editorExit = $LASTEXITCODE
    $editorProblems = @($editorOutput | Where-Object {
        $line = [string]$_
        $line.Contains('ERROR:') -or $line.Contains('WARNING:')
    })
    if ($editorExit -ne 0 -or $editorProblems.Count -gt 0) {
        $editorOutput | Select-Object -Last 40 | ForEach-Object { Write-Host $_ }
        throw "Импорт Godot завершился с кодом $editorExit или сообщениями об ошибках."
    }

    Write-Host 'Экспорт Windows Desktop...'
    $exportOutput = & $godotPath --headless --path $projectRoot --export-release 'Windows Desktop' $gameExecutable 2>&1
    $exportExit = $LASTEXITCODE
    $exportProblems = @($exportOutput | Where-Object {
        $line = [string]$_
        $line.Contains('ERROR:') -or $line.Contains('WARNING:')
    })
    if ($exportExit -ne 0 -or $exportProblems.Count -gt 0) {
        $exportOutput | Select-Object -Last 50 | ForEach-Object { Write-Host $_ }
        throw "Экспорт Windows Desktop завершился с кодом $exportExit или сообщениями об ошибках."
    }
}
finally {
    Pop-Location
}

New-Item -ItemType Directory -Path $runtimeDestination -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $runtimeDestination 'ollama.exe'))) {
    Copy-Item -LiteralPath (Join-Path $ollamaRoot 'ollama.exe') -Destination $runtimeDestination
}
if (-not (Test-Path -LiteralPath (Join-Path $runtimeDestination 'lib'))) {
    Copy-Item -LiteralPath (Join-Path $ollamaRoot 'lib') -Destination $runtimeDestination -Recurse
}
if (-not (Test-Path -LiteralPath (Join-Path $runtimeDestination 'models/manifests'))) {
    Copy-Item -LiteralPath $modelsRoot -Destination (Join-Path $runtimeDestination 'models') -Recurse
}

if (-not (Test-Path -LiteralPath $gameExecutable)) {
    throw "Godot не создал исполняемый файл: $gameExecutable"
}
if (-not (Test-Path -LiteralPath (Join-Path $runtimeDestination 'models/manifests'))) {
    throw 'В пакет не попал model store Ollama.'
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'CLIENT-README.md') -Destination (Join-Path $outputRoot 'README.md') -Force
$manifestRelativePath = [System.IO.Path]::GetRelativePath($modelsRoot, $manifestPath)
$packagedManifestPath = Join-Path (Join-Path $runtimeDestination 'models') $manifestRelativePath
if (-not (Test-Path -LiteralPath $packagedManifestPath)) {
    throw "В пакет не попала настроенная модель '$modelName'."
}
$packagedManifest = Get-Content -LiteralPath $packagedManifestPath -Raw | ConvertFrom-Json
if ($packagedManifest.config.digest -ne $manifest.config.digest -or
    @($packagedManifest.layers).Count -ne @($manifest.layers).Count) {
    throw "Manifest модели '$modelName' в пакете отличается от проверенного источника."
}
foreach ($layer in @($manifest.config) + @($manifest.layers)) {
    $blobName = $layer.digest.Replace(':', '-')
    $packagedBlob = Join-Path $runtimeDestination (Join-Path 'models/blobs' $blobName)
    if (-not (Test-Path -LiteralPath $packagedBlob) -or
        (Get-Item -LiteralPath $packagedBlob).Length -ne [long]$layer.size) {
        throw "В packaged model store отсутствует или повреждён слой $($layer.digest)."
    }
    $packagedBlobHash = (Get-FileHash -LiteralPath $packagedBlob -Algorithm SHA256).Hash
    if ($packagedBlobHash -ne $layer.digest.Substring(7)) {
        throw "SHA-256 packaged model store не совпадает для слоя $($layer.digest)."
    }
}
$packagedOllamaHash = (Get-FileHash -LiteralPath (Join-Path $runtimeDestination 'ollama.exe') -Algorithm SHA256).Hash
if ($packagedOllamaHash -ne $ollamaHash) {
    throw 'SHA-256 Ollama в готовом пакете не совпадает с проверенной версией.'
}

Write-Host "Готовый автономный Windows-пакет: $outputRoot"
Write-Host "Запуск игры: $gameExecutable"
