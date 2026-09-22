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
поэтому запускайте их из `pwsh`, например
`pwsh -NoProfile -File Tests/Run-DialogueModelEvaluation.ps1 -ReportPath <файл>`.

Утверждения в `Tests/DialogueRegression.Tests.ps1` написаны позиционным синтаксисом Pester
(`Should Be`, `Should Not Match`). Он работает на Pester 3.4/4.x и не работает на Pester 5, где эти
формы удалены; `Should -Be` в свою очередь не принимает Pester 3.4. На этой машине доступен
Pester 3.4.0 из `C:\Program Files\WindowsPowerShell\Modules`.

Перед прогоном оценки прогрейте модель и удержите её в VRAM (`keep_alive`): сам harness прогрев не
выполняет, и без него первый же замер не пройдёт критерий «первый текст < 5 секунд».

Прогон оценки:

```text
pwsh -NoProfile -File Tests/Run-DialogueModelEvaluation.ps1 `
    -ReportPath .scratch/npc-local-llm-demo/evaluation-<модель>.json `
    -ReviewPath .scratch/npc-local-llm-demo/review-<модель>.md
```

Автоматически проверяется только механика ответа: завершение потока, время до первого текста, пустой
ответ, дословный повтор сообщения игрока и длина до 50 слов. Отчёт содержит поля `MechanicallyClean`
и `MechanicalFaults`; код возврата 1 означает найденный механический дефект, а не непригодность модели.

Смысл ответа, сохранение роли и манеру речи проверяет человек по листу просмотра `-ReviewPath`: там
повторы одного сценария собраны под одну отметку. Прежние правила поиска «нужного слова» в ответе
удалены: на свободном русском они отвергали корректные реплики, детали — ADR-0003, уточнение 2.
Механические правила покрыты тестами в `Tests/DialogueResponseFault.Tests.ps1`.

Отчёты в `.scratch/npc-local-llm-demo/` порождены разными версиями harness'а. Действующий прогон для
текущего кода — `evaluation-qwen35-review.json` вместе с `review-qwen35.md`: у него есть
`ContextBuilderSha256`, и он сверяется с текущим `ContextBuilder.cs`. Четыре файла от 22 сентября с
полями `Pass`/`Failures` относятся к автоклассификации и остаются историческим материалом.

`Tests/DialogueSmoke.tscn` — сцены ручного smoke-проверок в окне Godot.

## Направление проекта

- диалог игрока с 2D placeholder-персонажем;
- локальный запуск языковой модели;
- дальнейшее подключение игрового интерфейса к локальному LLM-сервису.

## Godot MCP для Codex

Репозиторий содержит проектную конфигурацию Codex в `.codex/config.toml`. Она подключает внешний `@coding-solo/godot-mcp@0.1.1` через `npx` и использует путь к локальному Godot из `GODOT_PATH`.

Если Godot установлен в другом месте, замените `GODOT_PATH` в `.codex/config.toml`. После изменения конфигурации перезапустите Codex или начните новую локальную сессию. MCP-сервер работает как инструмент разработки и не добавляется в `project.godot`.
