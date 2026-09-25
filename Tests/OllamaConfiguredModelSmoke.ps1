param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../LocalLlmConfig.tres')
)

$ErrorActionPreference = 'Stop'

function Read-ResourceString([string]$Name, [string]$Contents) {
    $pattern = '(?m)^' + [regex]::Escape($Name) + '\s*=\s*"([^"]*)"\s*$'
    $match = [regex]::Match($Contents, $pattern)
    if (-not $match.Success) {
        throw "В '$ConfigPath' не найдено строковое свойство $Name."
    }

    return $match.Groups[1].Value
}

$config = Get-Content -LiteralPath $ConfigPath -Raw
$baseUrl = (Read-ResourceString 'BaseUrl' $config).TrimEnd('/')
$endpointPath = Read-ResourceString 'EndpointPath' $config
$modelName = Read-ResourceString 'ModelName' $config

$tags = Invoke-WebRequest "$baseUrl/api/tags" -SkipHttpErrorCheck -TimeoutSec 10
if ($tags.StatusCode -ne 200) {
    throw "GET /api/tags вернул HTTP $($tags.StatusCode). Проверьте Ollama по адресу $baseUrl."
}

$models = ($tags.Content | ConvertFrom-Json).models
if (-not ($models | Where-Object { $_.name -ceq $modelName })) {
    throw "Модель '$modelName' из LocalLlmConfig.tres отсутствует в ответе Ollama /api/tags."
}

$payload = @{
    model = $modelName
    messages = @(@{ role = 'user'; content = 'Ответь одним словом: готов.' })
    stream = $false
    think = $false
    options = @{ num_predict = 1; num_ctx = 2048 }
    keep_alive = '0'
} | ConvertTo-Json -Depth 6

$response = Invoke-WebRequest "$baseUrl$endpointPath" -Method Post -ContentType 'application/json' `
    -Body $payload -SkipHttpErrorCheck -TimeoutSec 120
if ($response.StatusCode -ne 200) {
    $details = $response.Content
    try {
        $details = ($response.Content | ConvertFrom-Json).error
    }
    catch { }
    throw "Ollama перечисляет '$modelName', но $endpointPath вернул HTTP $($response.StatusCode): $details"
}

$result = $response.Content | ConvertFrom-Json
if (-not $result.done) {
    throw "Ollama не завершил пробную генерацию для '$modelName'."
}

Write-Output "PASS: настроенная модель '$modelName' отвечает через $endpointPath."
