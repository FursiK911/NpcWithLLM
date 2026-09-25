Describe 'GDScript dialogue regression' {
    BeforeAll {
        $godotCommand = if ($env:GODOT_EXECUTABLE) {
            Get-Item -LiteralPath $env:GODOT_EXECUTABLE -ErrorAction Stop
        } else {
            Get-Command godot -ErrorAction SilentlyContinue
        }
        if ($null -eq $godotCommand) {
            throw 'Укажите стандартный Godot 4.x через GODOT_EXECUTABLE или добавьте godot в PATH.'
        }
        $script:godotPath = if ($godotCommand.Source) { $godotCommand.Source } else { $godotCommand.FullName }
        $script:projectRoot = Split-Path -Parent $PSScriptRoot
    }

    It 'passes memory, history, context, request, and Ollama lifecycle checks without .NET' {
        $output = @(& $script:godotPath --headless --path $script:projectRoot --script res://Tests/GdscriptRegression.gd 2>&1)
        $exitCode = $LASTEXITCODE
        $joined = $output -join "`n"
        $exitCode | Should Be 0
        $joined | Should Match 'PASS: GDScript regression checks'
        $joined | Should Not Match 'SCRIPT ERROR:|ERROR:'
    }
}
