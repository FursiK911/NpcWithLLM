# Graph Report - NpcWithLLM  (2026-09-24)

## Corpus Check
- 196 files · ~551,889 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 818 nodes · 993 edges · 83 communities (50 shown, 33 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 21 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `30e30b25`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Main
- NpcPersona
- template.sh
- What You Must Do When Invoked
- Matt Pocock workflow integration
- hitl-loop.template.sh
- LocalLlmResponder
- NpcWithLLM.csproj
- graphify reference: extra exports and benchmark
- graphify reference: query, path, explain
- graphify reference: add a URL and watch a folder
- graphify reference: commit hook and native CLAUDE.md integration
- graphify reference: incremental update and cluster-only
- Диалог с NPC
- Граница подключения локальной языковой модели
- graphify reference: GitHub clone and cross-repo merge
- graphify reference: transcribe video and audio
- extraction-spec.md
- Локальная оценка `Bonsai 2 27B PTQ1_0`
- OllamaServerController
- Local LLM Connection
- Локальная LLM в диалоге с NPC
- Bundled локальный runtime для LLM
- 01-2d-dialogue-scene.md
- 02: Память персонажа и ограниченный контекст
- Comments
- FakeLocalLlmRuntime
- .Create
- DialogueMessage.cs
- NpcMemory
- DialogueSmoke
- Полный адаптивный диалог
- Лист просмотра ответов персонажа
- Пороги приёмки снимаются, роль переезжает в профиль
- 12: Портреты механика и эмоции ответов
- Полная беседа
- Quality gate для естественного диалога NPC
- 0008-structured-character-response.md
- Node3D
- 0009-qwen35-9b-default.md
- LocalLlmConfig
- Полная беседа
- Node
- Exception
- Uri
- Project-local Godot MCP
- Лист просмотра ответов персонажа
- bool
- Bonsai2PrismRuntime
- DialogueHistory
- ChatResponder
- NpcPersona
- ContextBuilder
- Полная беседа
- NpcPersona
- Полная беседа
- Полная беседа
- Bonsai 2 временно выбрана провайдером игры по умолчанию
- Q: How do the current game profile, context, memory, history, and generation settings flow into the local model request?
- Q: How does the game select the local LLM provider and where is the runtime seam?
- Оценивать локальную модель живым диалогом
- 04-hidden-ollama-lifecycle.md
- 05-verified-model-provisioning.md
- 07-startup-readiness-ui.md
- 08-windows-package-and-docs.md
- 09-clean-windows-smoke.md
- LocalLlmConfig
- 11: Вступительная модалка для игрока
- DialogueHistory
- NpcProfile
- Exception
- DialogueMessage
- int
- NpcMemory
- Stopwatch
- Task

## God Nodes (most connected - your core abstractions)
1. `Полный адаптивный диалог` - 33 edges
2. `Полная беседа` - 33 edges
3. `Полная беседа` - 33 edges
4. `Полная беседа` - 33 edges
5. `Полная беседа` - 33 edges
6. `Полная беседа` - 33 edges
7. `Main` - 30 edges
8. `Bonsai2PrismRuntime` - 29 edges
9. `OllamaServerController` - 23 edges
10. `Лист просмотра ответов персонажа` - 21 edges

## Surprising Connections (you probably didn't know these)
- `LocalLlmResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmResponder.cs → Scripts/ChatResponder.cs
- `Bonsai2PrismRuntime` --references--> `LocalLlmConfig`  [EXTRACTED]
  Scripts/Dialogue/Bonsai2PrismRuntime.cs → Scripts/Dialogue/LocalLlmConfig.cs
- `FakeLocalLlmRuntime` --references--> `LocalLlmFailureKind`  [EXTRACTED]
  Scripts/Dialogue/FakeLocalLlmRuntime.cs → Scripts/Dialogue/LocalLlmRuntimeException.cs
- `LocalLlmRuntime` --implements--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmRuntime.cs → Scripts/Dialogue/ILocalLlmRuntime.cs
- `Main` --references--> `ChatResponder`  [EXTRACTED]
  Scripts/Main.cs → Scripts/ChatResponder.cs

## Import Cycles
- None detected.

## Communities (83 total, 33 thin omitted)

### Community 0 - "Main"
Cohesion: 0.07
Nodes (19): Button, Control, double, FocusModeEnum, InputEvent, Label, Node2D, RandomNumberGenerator (+11 more)

### Community 2 - "template.sh"
Cohesion: 0.22
Nodes (16): ask(), ask_secret(), banner(), _clear(), finish(), note(), open_url(), pause() (+8 more)

### Community 3 - "What You Must Do When Invoked"
Cohesion: 0.08
Nodes (24): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Part A - Structural extraction for code files (+16 more)

### Community 4 - "Matt Pocock workflow integration"
Cohesion: 0.14
Nodes (13): `code-review`, `diagnosing-bugs`, Graphify integration, `grill-with-docs`, `implement`, `improve-codebase-architecture` / `codebase-design`, Keeping the graph current, Matt Pocock workflow integration (+5 more)

### Community 5 - "hitl-loop.template.sh"
Cohesion: 0.83
Nodes (3): capture(), hitl-loop.template.sh script, step()

### Community 6 - "LocalLlmResponder"
Cohesion: 0.09
Nodes (17): CancellationTokenSource, LocalLlmConfig, LocalLlmRuntimeException, ContextBuilder, DialogueHistory, DialogueMessage, IReadOnlyList, NpcMemory (+9 more)

### Community 8 - "graphify reference: extra exports and benchmark"
Cohesion: 0.22
Nodes (8): graphify reference: extra exports and benchmark, Step 6b - Wiki (only if --wiki flag), Step 7 - Neo4j export (only if --neo4j or --neo4j-push flag), Step 7a - FalkorDB export (only if --falkordb or --falkordb-push flag), Step 7b - SVG export (only if --svg flag), Step 7c - GraphML export (only if --graphml flag), Step 7d - MCP server (only if --mcp flag), Step 8 - Token reduction benchmark (only if total_words > 5000)

### Community 9 - "graphify reference: query, path, explain"
Cohesion: 0.33
Nodes (5): For /graphify explain, For /graphify path, graphify reference: query, path, explain, Step 0 — Constrained query expansion (REQUIRED before traversal), Step 1 — Traversal

### Community 10 - "graphify reference: add a URL and watch a folder"
Cohesion: 0.50
Nodes (3): For /graphify add, For --watch, graphify reference: add a URL and watch a folder

### Community 11 - "graphify reference: commit hook and native CLAUDE.md integration"
Cohesion: 0.50
Nodes (3): For git commit hook, For native CLAUDE.md integration, graphify reference: commit hook and native CLAUDE.md integration

### Community 12 - "graphify reference: incremental update and cluster-only"
Cohesion: 0.50
Nodes (3): For --cluster-only, For --update (incremental re-extraction), graphify reference: incremental update and cluster-only

### Community 13 - "Диалог с NPC"
Cohesion: 0.50
Nodes (3): Диалог, Диалог с NPC, Локальная генерация

### Community 14 - "Граница подключения локальной языковой модели"
Cohesion: 0.29
Nodes (6): Consequences, Considered Options, Module Shape, Request Sequence, Test Surface, Граница подключения локальной языковой модели

### Community 18 - "Локальная оценка `Bonsai 2 27B PTQ1_0`"
Cohesion: 0.12
Nodes (14): 10: Локальная оценка Bonsai 2 27B, Comments, Готово, когда, Контекст, Требования, Выбор Bonsai по умолчанию и проверка обычного запуска (2026-09-24), Вывод и рекомендация, Итог (+6 more)

### Community 19 - "OllamaServerController"
Cohesion: 0.09
Nodes (21): Exception, IDisposable, JsonSerializerOptions, NetHttpClient, object, Process, Action, CancellationToken (+13 more)

### Community 20 - "Local LLM Connection"
Cohesion: 0.22
Nodes (8): Further Notes, Implementation Decisions, Local LLM Connection, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories

### Community 21 - "Локальная LLM в диалоге с NPC"
Cohesion: 0.18
Nodes (10): Further Notes, Implementation Decisions, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories, Локальная LLM в диалоге с NPC (+2 more)

### Community 22 - "Bundled локальный runtime для LLM"
Cohesion: 0.50
Nodes (3): Bundled локальный runtime для LLM, Consequences, Considered Options

### Community 25 - "Comments"
Cohesion: 0.25
Nodes (7): 03: Настоящий ответ локальной LLM, 2026-09-22 — приёмка разделена: механика автоматически, смысл за человеком, 2026-09-22 — проверяемость тестов и повторный прогон гейта, 2026-09-23 — попытка UI smoke через Godot MCP, 2026-09-23 — роль в профиле, числовые пороги сняты (ADR-0005), 2026-09-23 — успешный end-to-end smoke через headless harness, Comments

### Community 26 - "FakeLocalLlmRuntime"
Cohesion: 0.13
Nodes (13): Action, CancellationToken, DialogueMessage, Exception, IReadOnlyList, Task, FakeLocalLlmRuntime, Action (+5 more)

### Community 27 - ".Create"
Cohesion: 0.29
Nodes (6): JsonElement, DialogueMessage, IReadOnlyList, LocalLlmGenerationOptions, LocalLlmRequestBuilder, LocalLlmRequestPayload

### Community 29 - "NpcMemory"
Cohesion: 0.24
Nodes (4): Dictionary, IReadOnlyDictionary, Regex, NpcMemory

### Community 30 - "DialogueSmoke"
Cohesion: 0.10
Nodes (16): Action, CancellationToken, ILocalLlmRuntime, int, Memory, SeekOrigin, Stream, TaskCompletionSource (+8 more)

### Community 34 - "Полный адаптивный диалог"
Cohesion: 0.04
Nodes (44): Godot MCP для Codex, NpcWithLLM, Направление проекта, Ручной запуск Bonsai через PrismML, Текущий статус, Тесты и проверка качества, Итог, Локальная оценка `Qwen3.5 9B Q4_K_M` (+36 more)

### Community 35 - "Лист просмотра ответов персонажа"
Cohesion: 0.09
Nodes (21): assumption_correction, attack_identity, attack_memory, attack_progressive, attack_prompt, attack_roleplay, attack_system, attack_translation (+13 more)

### Community 36 - "Пороги приёмки снимаются, роль переезжает в профиль"
Cohesion: 0.50
Nodes (3): Consequences, Considered Options, Пороги приёмки снимаются, роль переезжает в профиль

### Community 38 - "12: Портреты механика и эмоции ответов"
Cohesion: 0.40
Nodes (4): 12: Портреты механика и эмоции ответов, Comments, Контекст, Требования

### Community 39 - "Полная беседа"
Cohesion: 0.05
Nodes (38): Вывод и рекомендация, Живая оценка `gemma4-12b-it-q2k-eval` (Gemma 4 12B IT, Q2_K), Оценки, Полная беседа, Сравнение с предыдущими прогонами, Условия прогона, Ход 1, Ход 10 (+30 more)

### Community 40 - "Quality gate для естественного диалога NPC"
Cohesion: 0.40
Nodes (4): Quality gate для естественного диалога NPC, Исторические последствия (до уточнения), Уточнение (2) от 2026-09-22: смысловую часть критерия проверяет человек, Уточнение от 2026-09-22

### Community 44 - "LocalLlmConfig"
Cohesion: 0.22
Nodes (6): NpcPersona, Resource, Uri, LocalLlmConfig, LocalLlmProvider, NpcProfile

### Community 45 - "Полная беседа"
Cohesion: 0.06
Nodes (33): Полная беседа, Ход 1, Ход 10, Ход 11, Ход 12, Ход 13, Ход 14, Ход 15 (+25 more)

### Community 46 - "Node"
Cohesion: 0.11
Nodes (10): Node, Bonsai2DefaultProviderSmoke, Task, Bonsai2InteractiveRunner, Bonsai2LiveDialogueEvaluationRunner, string, Task, string (+2 more)

### Community 51 - "Лист просмотра ответов персонажа"
Cohesion: 0.10
Nodes (19): attack_identity, attack_memory, attack_progressive, attack_prompt, attack_roleplay, attack_system, attack_translation, dialogue_history (+11 more)

### Community 53 - "Bonsai2PrismRuntime"
Cohesion: 0.11
Nodes (19): Func, GenerationResult, HttpClient, IReadOnlyList, Bonsai2PrismRuntime, bool, CancellationToken, DialogueMessage (+11 more)

### Community 54 - "DialogueHistory"
Cohesion: 0.14
Nodes (12): HttpMessageHandler, HttpRequestMessage, HttpResponseMessage, List, Queue, DialogueMessage, int, IReadOnlyList (+4 more)

### Community 59 - "Полная беседа"
Cohesion: 0.05
Nodes (39): 06: Живая оценка локальной модели, Comments, Вывод и рекомендация, Живая оценка `qwen3.5:4b`, Оценки, Полная беседа, Условия прогона, Ход 1 (+31 more)

### Community 62 - "Полная беседа"
Cohesion: 0.05
Nodes (38): Вывод и рекомендация, Живая оценка `qwen3:4b-instruct`, Оценки, Полная беседа, Проверка памяти, Условия прогона, Ход 1, Ход 10 (+30 more)

### Community 63 - "Полная беседа"
Cohesion: 0.05
Nodes (37): Живая оценка `ministral-3:8b-instruct-2512-q4_K_M`, Оценки, Полная беседа, Сравнение и рекомендация, Условия прогона, Ход 1, Ход 10, Ход 11 (+29 more)

### Community 64 - "Bonsai 2 временно выбрана провайдером игры по умолчанию"
Cohesion: 0.33
Nodes (5): Bonsai 2 временно выбрана провайдером игры по умолчанию, Контекст, Ограничения и эксплуатация, Последствия, Решение

### Community 65 - "Q: How do the current game profile, context, memory, history, and generation settings flow into the local model request?"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: How do the current game profile, context, memory, history, and generation settings flow into the local model request?, Source Nodes

### Community 66 - "Q: How does the game select the local LLM provider and where is the runtime seam?"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: How does the game select the local LLM provider and where is the runtime seam?, Source Nodes

### Community 67 - "Оценивать локальную модель живым диалогом"
Cohesion: 0.50
Nodes (3): Оценивать локальную модель живым диалогом, Последствия, Рассматриваемые варианты

### Community 74 - "11: Вступительная модалка для игрока"
Cohesion: 0.40
Nodes (4): 11: Вступительная модалка для игрока, Comments, Контекст, Требования

## Knowledge Gaps
- **383 isolated node(s):** `Comments`, `Контекст`, `Требования`, `Готово, когда`, `Comments` (+378 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **33 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Work-memory lessons

**Preferred sources** — corroborated by past sessions; start here.
- `LocalLlmResponder` (2× useful, score=1.950453005) _(code changed — re-verify)_
- `LocalLlmRuntime` (2× useful, score=1.950453005)

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatResponder` connect `Main` to `Node`, `LocalLlmResponder`?**
  _High betweenness centrality (0.049) - this node is a cross-community bridge._
- **Why does `Main` connect `Main` to `NpcMemory`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Why does `Bonsai2PrismRuntime` connect `Bonsai2PrismRuntime` to `OllamaServerController`, `LocalLlmConfig`, `DialogueSmoke`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **What connects `Comments`, `Контекст`, `Требования` to the rest of the system?**
  _383 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Main` be split into smaller, more focused modules?**
  _Cohesion score 0.06852497096399536 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Matt Pocock workflow integration` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._