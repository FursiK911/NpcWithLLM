# Механические свойства ответа персонажа. Смысловую пригодность ответа проверяет человек
# по листу просмотра: автоматический поиск «нужного слова» в свободном русском ответе
# даёт ложные отвержения и не является критерием пригодности модели (ADR-0003).
function Get-DialogueResponseFault {
    param(
        [Parameter(Mandatory)][string]$PlayerMessage,
        [Parameter(Mandatory)][string]$Content,
        [nullable[double]]$FirstTextMs,
        [bool]$Completed = $true
    )

    $normalizedContent = ($Content -replace '\s+', ' ').Trim()
    $wordCount = if ([string]::IsNullOrWhiteSpace($normalizedContent)) { 0 } else { ($normalizedContent -split ' ').Count }
    $repeatsPlayerMessage = $normalizedContent -eq (($PlayerMessage -replace '\s+', ' ').Trim())

    $faults = [System.Collections.Generic.List[string]]::new()
    if (-not $Completed) { $faults.Add('incomplete stream') }
    if ($null -eq $FirstTextMs -or $FirstTextMs -ge 5000) { $faults.Add('first text >= 5 seconds or missing') }
    if ([string]::IsNullOrWhiteSpace($normalizedContent)) { $faults.Add('empty response') }
    if ($repeatsPlayerMessage) { $faults.Add('copies player message') }
    if ($wordCount -gt 50) { $faults.Add("too long: $wordCount words") }

    return ,$faults
}
