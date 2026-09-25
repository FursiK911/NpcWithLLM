param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../LocalLlmConfig.tres')
)

$ErrorActionPreference = 'Stop'

function Read-ResourceValue([string]$Name, [string]$Contents) {
    $pattern = '(?m)^' + [regex]::Escape($Name) + '\s*=\s*(?:"([^"]*)"|([^\r\n#]+))\s*$'
    $match = [regex]::Match($Contents, $pattern)
    if (-not $match.Success) {
        throw "В '$ConfigPath' не найдено свойство $Name."
    }

    if ($match.Groups[1].Success) {
        return $match.Groups[1].Value
    }
    return $match.Groups[2].Value.Trim()
}

$config = Get-Content -LiteralPath $ConfigPath -Raw
$baseUrl = (Read-ResourceValue 'base_url' $config).TrimEnd('/')
$endpointPath = Read-ResourceValue 'endpoint_path' $config
$modelName = Read-ResourceValue 'model_name' $config
$temperature = [double](Read-ResourceValue 'temperature' $config)
$topP = [double](Read-ResourceValue 'top_p' $config)
$maxTokens = [int](Read-ResourceValue 'max_tokens' $config)
$contextTokens = [int](Read-ResourceValue 'context_tokens' $config)
$presencePenalty = [double](Read-ResourceValue 'presence_penalty' $config)

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
    format = @{
        type = 'object'
        properties = @{
            message = @{ type = 'string' }
            emotion = @{ type = 'string'; enum = @('angry', 'happy', 'sad', 'thinking', 'neutral') }
        }
        required = @('message', 'emotion')
        additionalProperties = $false
    }
    options = @{
        temperature = $temperature
        top_p = $topP
        num_predict = $maxTokens
        num_ctx = $contextTokens
        presence_penalty = $presencePenalty
        repeat_penalty = 1.0
    }
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
try {
    $characterResponse = $result.message.content | ConvertFrom-Json
}
catch {
    throw "Ollama не вернула структурированный JSON-ответ для '$modelName'."
}
if ([string]::IsNullOrWhiteSpace($characterResponse.message) -or
    $characterResponse.emotion -notin @('angry', 'happy', 'sad', 'thinking', 'neutral')) {
    throw "JSON-ответ модели '$modelName' не содержит допустимые поля message и emotion."
}

Write-Output "PASS: настроенная модель '$modelName' отвечает через $endpointPath."
