# Graph Report - NpcWithLLM  (2026-09-23)

## Corpus Check
- 173 files · ~127,723 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 552 nodes · 612 edges · 65 communities (40 shown, 25 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4577e213`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Main
- DialogueHistory
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
- NpcWithLLM
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
- LocalLlmRuntimeException
- Лист просмотра ответов персонажа
- Пороги приёмки снимаются, роль переезжает в профиль
- bool
- ILocalLlmRuntime
- Quality gate для естественного диалога NPC
- JsonElement
- Node3D
- NpcMemory
- NpcPersona
- Uri
- DialogueMessage
- Exception
- Uri
- Project-local Godot MCP
- Лист просмотра ответов персонажа
- MockChatResponder
- int
- IReadOnlyList
- DialogueHistory
- NpcPersona
- DialogueHistory
- Полная беседа
- NpcPersona
- Полная беседа
- Полная беседа
- Живая оценка `qwen3.5:4b`

## God Nodes (most connected - your core abstractions)
1. `Полная беседа` - 33 edges
2. `Полная беседа` - 33 edges
3. `Полная беседа` - 33 edges
4. `OllamaServerController` - 23 edges
5. `Main` - 23 edges
6. `Лист просмотра ответов персонажа` - 21 edges
7. `LocalLlmResponder` - 19 edges
8. `Лист просмотра ответов персонажа` - 19 edges
9. `DialogueSmoke` - 13 edges
10. `What You Must Do When Invoked` - 12 edges

## Surprising Connections (you probably didn't know these)
- `FakeLocalLlmRuntime` --implements--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/FakeLocalLlmRuntime.cs → Scripts/Dialogue/ILocalLlmRuntime.cs
- `LocalLlmRuntime` --implements--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmRuntime.cs → Scripts/Dialogue/ILocalLlmRuntime.cs
- `FakeLocalLlmRuntime` --references--> `LocalLlmFailureKind`  [EXTRACTED]
  Scripts/Dialogue/FakeLocalLlmRuntime.cs → Scripts/Dialogue/LocalLlmRuntimeException.cs
- `MockChatResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/MockChatResponder.cs → Scripts/ChatResponder.cs
- `LocalLlmResponder` --references--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmResponder.cs → Scripts/Dialogue/ILocalLlmRuntime.cs

## Import Cycles
- None detected.

## Communities (65 total, 25 thin omitted)

### Community 0 - "Main"
Cohesion: 0.10
Nodes (11): Button, InputEvent, Label, Node, Node2D, RichTextLabel, ChatResponder, bool (+3 more)

### Community 1 - "DialogueHistory"
Cohesion: 0.09
Nodes (14): List, Resource, ContextBuilder, DialogueMessage, IReadOnlyList, NpcMemory, DialogueContext, DialogueMessage (+6 more)

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
Nodes (17): CancellationTokenSource, ChatResponder, ContextBuilder, DialogueHistory, NpcMemory, NpcProfile, Action, CancellationToken (+9 more)

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

### Community 18 - "NpcWithLLM"
Cohesion: 0.29
Nodes (6): Godot MCP для Codex, NpcWithLLM, Направление проекта, Ручной запуск Ollama, Текущий статус, Тесты и проверка качества

### Community 19 - "OllamaServerController"
Cohesion: 0.09
Nodes (23): Exception, HttpClient, IDisposable, JsonSerializerOptions, NetHttpClient, object, Process, Action (+15 more)

### Community 20 - "Local LLM Connection"
Cohesion: 0.22
Nodes (8): Further Notes, Implementation Decisions, Local LLM Connection, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories

### Community 21 - "Локальная LLM в диалоге с NPC"
Cohesion: 0.20
Nodes (9): Further Notes, Implementation Decisions, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories, Локальная LLM в диалоге с NPC (+1 more)

### Community 22 - "Bundled локальный runtime для LLM"
Cohesion: 0.50
Nodes (3): Bundled локальный runtime для LLM, Consequences, Considered Options

### Community 25 - "Comments"
Cohesion: 0.25
Nodes (7): 03: Настоящий ответ локальной LLM, 2026-09-22 — приёмка разделена: механика автоматически, смысл за человеком, 2026-09-22 — проверяемость тестов и повторный прогон гейта, 2026-09-23 — попытка UI smoke через Godot MCP, 2026-09-23 — роль в профиле, числовые пороги сняты (ADR-0005), 2026-09-23 — успешный end-to-end smoke через headless harness, Comments

### Community 26 - "FakeLocalLlmRuntime"
Cohesion: 0.28
Nodes (7): Action, CancellationToken, DialogueMessage, Exception, IReadOnlyList, Task, FakeLocalLlmRuntime

### Community 27 - ".Create"
Cohesion: 0.33
Nodes (5): DialogueMessage, IReadOnlyList, LocalLlmGenerationOptions, LocalLlmRequestBuilder, LocalLlmRequestPayload

### Community 29 - "NpcMemory"
Cohesion: 0.24
Nodes (4): Dictionary, IReadOnlyDictionary, Regex, NpcMemory

### Community 30 - "DialogueSmoke"
Cohesion: 0.09
Nodes (19): Action, CancellationToken, HttpMessageHandler, HttpRequestMessage, HttpResponseMessage, ILocalLlmRuntime, Memory, SeekOrigin (+11 more)

### Community 35 - "Лист просмотра ответов персонажа"
Cohesion: 0.09
Nodes (21): assumption_correction, attack_identity, attack_memory, attack_progressive, attack_prompt, attack_roleplay, attack_system, attack_translation (+13 more)

### Community 36 - "Пороги приёмки снимаются, роль переезжает в профиль"
Cohesion: 0.50
Nodes (3): Consequences, Considered Options, Пороги приёмки снимаются, роль переезжает в профиль

### Community 40 - "Quality gate для естественного диалога NPC"
Cohesion: 0.40
Nodes (4): Quality gate для естественного диалога NPC, Исторические последствия (до уточнения), Уточнение (2) от 2026-09-22: смысловую часть критерия проверяет человек, Уточнение от 2026-09-22

### Community 51 - "Лист просмотра ответов персонажа"
Cohesion: 0.10
Nodes (19): attack_identity, attack_memory, attack_progressive, attack_prompt, attack_roleplay, attack_system, attack_translation, dialogue_history (+11 more)

### Community 52 - "MockChatResponder"
Cohesion: 0.33
Nodes (4): double, MockChatResponder, string, Task

### Community 59 - "Полная беседа"
Cohesion: 0.06
Nodes (33): Полная беседа, Ход 1, Ход 10, Ход 11, Ход 12, Ход 13, Ход 14, Ход 15 (+25 more)

### Community 62 - "Полная беседа"
Cohesion: 0.05
Nodes (38): Вывод и рекомендация, Живая оценка `qwen3:4b-instruct`, Оценки, Полная беседа, Проверка памяти, Условия прогона, Ход 1, Ход 10 (+30 more)

### Community 63 - "Полная беседа"
Cohesion: 0.06
Nodes (33): Полная беседа, Ход 1, Ход 10, Ход 11, Ход 12, Ход 13, Ход 14, Ход 15 (+25 more)

### Community 64 - "Живая оценка `qwen3.5:4b`"
Cohesion: 0.15
Nodes (10): 06: Живая оценка локальной модели, Comments, Вывод и рекомендация, Живая оценка `qwen3.5:4b`, Оценки, Условия прогона, Живая оценка `ministral-3:8b-instruct-2512-q4_K_M`, Оценки (+2 more)

## Knowledge Gaps
- **240 isolated node(s):** `Comments`, `Условия прогона`, `Оценки`, `Сравнение и рекомендация`, `Ход 1` (+235 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `OllamaServerController` connect `OllamaServerController` to `MockChatResponder`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `ChatResponder` connect `Main` to `MockChatResponder`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `MockChatResponder` connect `MockChatResponder` to `Main`?**
  _High betweenness centrality (0.053) - this node is a cross-community bridge._
- **What connects `Comments`, `Условия прогона`, `Оценки` to the rest of the system?**
  _240 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Main` be split into smaller, more focused modules?**
  _Cohesion score 0.0960591133004926 - nodes in this community are weakly interconnected._
- **Should `DialogueHistory` be split into smaller, more focused modules?**
  _Cohesion score 0.08615384615384615 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._