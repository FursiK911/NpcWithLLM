# 01: Перенос исполняемого runtime на GDScript

**What to build:** Перевести исполняемый путь игры на GDScript, сохранив поведение локального диалога и возможность сборки обычным Godot 4.x без Godot .NET и .NET SDK.

**Status:** ready-for-human

- [x] Основная сцена, UI и seam `ChatResponder` используют GDScript.
- [x] Ollama runtime, конфигурация, контекст, память, история и разбор structured response реализованы на GDScript.
- [x] Endpoint, выбранная модель, порядок контекста, JSON Schema, ошибки и семантика обновления памяти покрыты regression/smoke-проверками.
- [x] Старый C# runtime удалён; необязательные источники для ручной оценки модели изолированы в `Tests/OptionalModelEvaluation/`.
- [x] Стандартный Godot 4.7.2 импортирует проект и экспортирует Windows executable.
- [x] Полный GDScript suite и запрос настроенной модели Ollama проходят.
- [x] README объясняет обычный Godot runtime и отдельно описывает необязательный C# evaluation harness.
- [x] Код прошёл ревью по стандартам проекта и по спецификации.

## Comments

- Принятый пользователем Google Doc задаёт текущие требования к стеку и игровому runtime; он заменяет относящиеся к стеку исторические допущения в старых заметках о реализации.
- `Tests/Run-DialogueModelEvaluation.ps1` и `Tests/OptionalModelEvaluation/*.cs` остаются инструментами ручной оценки модели. Они не нужны для запуска или Windows-экспорта игры.
