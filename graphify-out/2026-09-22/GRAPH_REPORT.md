# Graph Report - NpcWithLLM  (2026-09-22)

## Corpus Check
- 152 files · ~100,176 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 339 nodes · 384 edges · 50 communities (27 shown, 23 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `88929173`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Main
- LocalLlmResponder
- template.sh
- What You Must Do When Invoked
- Matt Pocock workflow integration
- hitl-loop.template.sh
- FakeLocalLlmRuntime
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
- .GenerateAsync
- Local LLM Connection
- Локальная LLM в диалоге с NPC
- Bundled локальный runtime для LLM
- 01-2d-dialogue-scene.md
- 02: Память персонажа и ограниченный контекст
- 03: Настоящий ответ локальной LLM
- 04-silent-bundled-ollama.md
- 05-windows-delivery-and-smoke-test.md
- DelayedStream
- NpcMemory
- DialogueSmoke
- MockChatResponder
- LocalLlmRuntimeException
- NpcPersona
- bool
- ChatResponder
- ContextBuilder
- DialogueHistory
- Quality gate для естественного диалога NPC
- JsonElement
- Node3D
- NpcMemory
- NpcPersona
- Uri
- ILocalLlmRuntime
- Exception
- Uri
- Project-local Godot MCP

## God Nodes (most connected - your core abstractions)
1. `Main` - 23 edges
2. `LocalLlmResponder` - 18 edges
3. `DialogueSmoke` - 13 edges
4. `What You Must Do When Invoked` - 12 edges
5. `NpcMemory` - 11 edges
6. `template.sh script` - 11 edges
7. `/graphify` - 10 edges
8. `DelayedStream` - 9 edges
9. `Matt Pocock workflow integration` - 9 edges
10. `Локальная LLM в диалоге с NPC` - 8 edges

## Surprising Connections (you probably didn't know these)
- `LocalLlmResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmResponder.cs → Scripts/ChatResponder.cs
- `MockChatResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/MockChatResponder.cs → Scripts/ChatResponder.cs
- `LocalLlmResponder` --references--> `ContextBuilder`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmResponder.cs → Scripts/Dialogue/ContextBuilder.cs
- `FakeLocalLlmRuntime` --implements--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/FakeLocalLlmRuntime.cs → Scripts/Dialogue/ILocalLlmRuntime.cs
- `LocalLlmRuntime` --implements--> `ILocalLlmRuntime`  [EXTRACTED]
  Scripts/Dialogue/LocalLlmRuntime.cs → Scripts/Dialogue/ILocalLlmRuntime.cs

## Import Cycles
- None detected.

## Communities (50 total, 23 thin omitted)

### Community 0 - "Main"
Cohesion: 0.10
Nodes (11): Button, InputEvent, Label, Node, Node2D, RichTextLabel, ChatResponder, bool (+3 more)

### Community 1 - "LocalLlmResponder"
Cohesion: 0.12
Nodes (13): CancellationTokenSource, Action, CancellationToken, DialogueMessage, IReadOnlyList, Task, ILocalLlmRuntime, bool (+5 more)

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

### Community 6 - "FakeLocalLlmRuntime"
Cohesion: 0.20
Nodes (10): Exception, Action, CancellationToken, DialogueMessage, Exception, IReadOnlyList, Task, FakeLocalLlmRuntime (+2 more)

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

### Community 19 - ".GenerateAsync"
Cohesion: 0.11
Nodes (16): JsonSerializerOptions, NetHttpClient, Resource, LocalLlmConfig, DialogueMessage, IReadOnlyList, LocalLlmGenerationOptions, LocalLlmRequestBuilder (+8 more)

### Community 20 - "Local LLM Connection"
Cohesion: 0.22
Nodes (8): Further Notes, Implementation Decisions, Local LLM Connection, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories

### Community 21 - "Локальная LLM в диалоге с NPC"
Cohesion: 0.20
Nodes (9): Further Notes, Implementation Decisions, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories, Локальная LLM в диалоге с NPC (+1 more)

### Community 22 - "Bundled локальный runtime для LLM"
Cohesion: 0.50
Nodes (3): Bundled локальный runtime для LLM, Consequences, Considered Options

### Community 25 - "03: Настоящий ответ локальной LLM"
Cohesion: 0.50
Nodes (3): 03: Настоящий ответ локальной LLM, 2026-09-22 — проверяемость тестов и повторный прогон гейта, Comments

### Community 28 - "DelayedStream"
Cohesion: 0.12
Nodes (8): int, List, IReadOnlyList, DialogueHistory, DialogueMessage, SeekOrigin, Stream, DelayedStream

### Community 29 - "NpcMemory"
Cohesion: 0.14
Nodes (10): Dictionary, IReadOnlyDictionary, Regex, ContextBuilder, DialogueHistory, DialogueMessage, IReadOnlyList, NpcPersona (+2 more)

### Community 30 - "DialogueSmoke"
Cohesion: 0.13
Nodes (15): Action, CancellationToken, DialogueMessage, HttpMessageHandler, HttpRequestMessage, HttpResponseMessage, ILocalLlmRuntime, IReadOnlyList (+7 more)

### Community 33 - "MockChatResponder"
Cohesion: 0.40
Nodes (3): double, MockChatResponder, string

### Community 40 - "Quality gate для естественного диалога NPC"
Cohesion: 0.50
Nodes (3): Quality gate для естественного диалога NPC, Исторические последствия (до уточнения), Уточнение от 2026-09-22

## Knowledge Gaps
- **90 isolated node(s):** `2026-09-22 — проверяемость тестов и повторный прогон гейта`, `Ручной запуск Ollama`, `Тесты и проверка качества`, `Направление проекта`, `Godot MCP для Codex` (+85 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ChatResponder` connect `Main` to `LocalLlmResponder`, `MockChatResponder`?**
  _High betweenness centrality (0.136) - this node is a cross-community bridge._
- **Why does `LocalLlmResponder` connect `LocalLlmResponder` to `Main`, `.GenerateAsync`, `NpcMemory`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Why does `DialogueSmoke` connect `DialogueSmoke` to `Main`, `DelayedStream`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **What connects `2026-09-22 — проверяемость тестов и повторный прогон гейта`, `Ручной запуск Ollama`, `Тесты и проверка качества` to the rest of the system?**
  _90 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Main` be split into smaller, more focused modules?**
  _Cohesion score 0.0960591133004926 - nodes in this community are weakly interconnected._
- **Should `LocalLlmResponder` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._