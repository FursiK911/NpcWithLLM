# Механические свойства ответа персонажа: только исправность транспорта. Числовые пороги приёмки
# здесь не живут: время до готовой реплики и длину ответа харнесс пишет в отчёт как замеры без
# вердикта, а пригодность ответа по смыслу, сохранение роли, манеру речи и скорость судит человек
# по листу просмотра (ADR-0003, ADR-0005).
function Get-DialogueResponseFault {
    param(
        [Parameter(Mandatory)][string]$PlayerMessage,
        [Parameter(Mandatory)][string]$Content,
        [bool]$Completed = $true
    )

    $normalizedContent = ($Content -replace '\s+', ' ').Trim()
    $repeatsPlayerMessage = $normalizedContent -eq (($PlayerMessage -replace '\s+', ' ').Trim())

    $faults = [System.Collections.Generic.List[string]]::new()
    if (-not $Completed) { $faults.Add('incomplete stream') }
    if ([string]::IsNullOrWhiteSpace($normalizedContent)) { $faults.Add('empty response') }
    if ($repeatsPlayerMessage) { $faults.Add('copies player message') }

    return ,$faults
}
