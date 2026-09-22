# NpcWithLLM

Небольшая 2D-сцена Godot 4.7 C# для диалога игрока с placeholder-NPC Иваном.

## Текущий статус

Сцена использует `LocalLlmResponder` и получает ответ от локального Ollama потоком: первый текст
персонажа появляется до окончания генерации.
Настройки подключения, модели, timeout и генерации находятся в `LocalLlmConfig.tres`; UI не знает о
HTTP или JSON. Для UI-проверок и тестов сохраняются `MockChatResponder` и `FakeLocalLlmRuntime`.

Текущая модель — `qwen3.5:4b`, кандидат quality gate из `docs/adr/0003-natural-dialogue-model-quality-gate.md`.
`qwen3.5:0.8b` из окружения удалена и непригодна для естественного диалога.

Эта issue подключает уже работающий loopback-сервис Ollama. Тихий запуск bundled Ollama, импорт и
прогрев модели относятся к следующей issue 04 и пока не входят в обычный запуск проекта.

### Ручной запуск Ollama

Для текущей разработки запустите Ollama отдельно и подготовьте модель:

```text
ollama serve
ollama pull qwen3.5:4b
```

После этого запустите проект в Godot 4.7.2 .NET и отправьте сообщение Ивану. Если сервис недоступен,
игра покажет понятную ошибку, сохранит введённый текст и позволит повторить отправку вручную.

`LocalLlmRuntime` отправляет `POST` на `http://127.0.0.1:11434/api/chat` с моделью из конфигурации,
`stream: true` и `think: false`, персоной, памятью персонажа, ограниченной историей и текущим
сообщением игрока. Системный контекст передаётся элементом `messages` с ролью `system`, а не
полем `system`: Ollama применяет поле `system` иначе, и на этом контракте была потеряна память игрока.
Параметры генерации сериализуются в именах API Ollama: `temperature`, `top_p`, `num_predict`, `num_ctx`.
URL принимает только loopback;
полный текст диалога не пишется в debug log;
в лог попадают только состояние запроса, endpoint, тип ошибки и техническая причина.

## Тесты и проверка качества

Сборка: `dotnet build NpcWithLLM.csproj`.

`Tests/DialogueRegression.Tests.ps1` (Pester) и `Tests/Run-DialogueModelEvaluation.ps1`
требуют **PowerShell 7**: оба компилируют исходники `Scripts/Dialogue` через `Add-Type`, а там C# 9
(records, target-typed new) и `System.Text.Json`. Windows PowerShell 5.1 останавливается на компиляции,
поэтому запускайте их из `pwsh`. На машине без PowerShell 7 эти проверки неприменимы — результат
оценивок в `.scratch/npc-local-llm-demo/evaluation-qwen35*.json` получен в другой среде и требует
повтора перед сменой статуса тикета.

`Tests/Run-DialogueModelEvaluation.ps1` прогоняет фиксированные сценарии по три раза через реальный
Ollama и пишет отчёт по `-ReportPath`; критерии приёмки — в ADR-0003 и `spec.md`.
`Tests/DialogueSmoke.tscn` — сцены ручного smoke-проверок в окне Godot.

## Направление проекта

- диалог игрока с 2D placeholder-персонажем;
- локальный запуск языковой модели;
- дальнейшее подключение игрового интерфейса к локальному LLM-сервису.

## Godot MCP для Codex

Репозиторий содержит проектную конфигурацию Codex в `.codex/config.toml`. Она подключает внешний `@coding-solo/godot-mcp@0.1.1` через `npx` и использует путь к локальному Godot из `GODOT_PATH`.

Если Godot установлен в другом месте, замените `GODOT_PATH` в `.codex/config.toml`. После изменения конфигурации перезапустите Codex или начните новую локальную сессию. MCP-сервер работает как инструмент разработки и не добавляется в `project.godot`.
