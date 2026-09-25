# Graph Report - NpcWithLLM  (2026-09-25)

## Corpus Check
- 192 files · ~589,281 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 971 nodes · 824 edges · 176 communities (76 shown, 100 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a87f61bf`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Button
- Issue tracker: GitHub
- template.sh
- What You Must Do When Invoked
- Matt Pocock workflow integration
- hitl-loop.template.sh
- IReadOnlyDictionary
- Локальная оценка `Bonsai 2 27B PTQ1_0`
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
- Issue tracker: Local Markdown
- Exception
- Local LLM Connection
- Локальная LLM в диалоге с NPC
- Bundled локальный runtime для LLM
- 01: Играбельная 2D-сцена диалога
- 02: Память персонажа и ограниченный контекст
- Comments
- Triage
- JsonElement
- teach/SKILL.md
- Process
- HttpMessageHandler
- Полный адаптивный диалог
- Лист просмотра ответов персонажа
- Пороги приёмки снимаются, роль переезжает в профиль
- 12: Портреты механика и эмоции ответов
- Полная беседа
- Quality gate для естественного диалога NPC
- 0008-structured-character-response.md
- Codebase Design
- 05: Проверка и подготовка выбранной модели
- During the session
- Полная беседа
- HTML Report Format
- Ask Matt
- Diagnosing Bugs
- Project-local Godot MCP
- Лист просмотра ответов персонажа
- Test-Driven Development
- Process
- writing-for-agents/SKILL.md
- wayfinder/SKILL.md
- to-spec/SKILL.md
- Полная беседа
- 3D Dialogue Vertical Slice
- Полная беседа
- Полная беседа
- Bonsai 2 временно выбрана провайдером игры по умолчанию
- Q: How do the current game profile, context, memory, history, and generation settings flow into the local model request?
- Q: How does the game select the local LLM provider and where is the runtime seam?
- Оценивать локальную модель живым диалогом
- 04: Скрытый жизненный цикл Ollama
- Memory
- 07-startup-readiness-ui.md
- 08-windows-package-and-docs.md
- 09-clean-windows-smoke.md
- Process
- 11: Вступительная модалка для игрока
- <Questionnaire title>
- Process
- Domain Docs
- Agent skills
- Q: что дальше по плану нужно реализовать?
- Q: Найди и предложи способы улучшить ответы и контекст у NPC и при этом не выходить за рамки технических требований
- Q: Удали все лишние файлы, которые не нужны для запуска текущей версии приложения. С bonsai я например вижу есть файлы. Prism ml насколько я вижу нам уже не нужен
- GLOSSARY.md Format
- agents/triage-labels.md
- CancellationTokenSource
- Сборка автономного Windows-пакета с нуля
- bool
- Uri
- bool
- CancellationTokenSource
- string
- ChatResponder
- ContextBuilder
- Control
- DialogueHistory
- double
- ExpectedSha256
- FocusModeEnum
- HttpClient
- HttpRequestMessage
- HttpResponseMessage
- IDisposable
- ILocalLlmRuntime
- InputEvent
- JsonSerializerOptions
- Label
- List
- NetHttpClient
- Node
- Node2D
- NpcMemory
- NpcProfile
- object
- Path
- Process
- RandomNumberGenerator
- Regex
- Resource
- RichTextLabel
- IReadOnlyList
- int
- IReadOnlyList
- Action
- CancellationToken
- Exception
- IReadOnlyList
- Task
- Action
- CancellationToken
- IReadOnlyList
- Task
- IReadOnlyList
- Exception
- Task
- Action
- CancellationToken
- CancellationTokenSource
- IReadOnlyList
- Task
- Dictionary
- bool
- CancellationToken
- string
- Task
- Uri
- bool
- Dictionary
- TextureRect
- string
- Task
- SeekOrigin
- SemaphoreSlim
- Stream
- string
- TaskCompletionSource
- Action
- CancellationToken
- int
- IReadOnlyList
- Task
- TextureRect
- Task
- TextEdit
- Texture2D
- TimeSpan
- Uri
- ValueTask

## God Nodes (most connected - your core abstractions)
1. `Полная беседа` - 33 edges
2. `Полная беседа` - 33 edges
3. `Полная беседа` - 33 edges
4. `Полная беседа` - 33 edges
5. `Полный адаптивный диалог` - 33 edges
6. `Полная беседа` - 33 edges
7. `Лист просмотра ответов персонажа` - 21 edges
8. `Лист просмотра ответов персонажа` - 19 edges
9. `What You Must Do When Invoked` - 12 edges
10. `template.sh script` - 11 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (176 total, 100 thin omitted)

### Community 1 - "Issue tracker: GitHub"
Cohesion: 0.06
Nodes (30): Before exploring, read these, Domain Docs, File structure, Flag ADR conflicts, Use the glossary's vocabulary, Conventions, Issue tracker: GitHub, Pull requests as a triage surface (+22 more)

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

### Community 7 - "Локальная оценка `Bonsai 2 27B PTQ1_0`"
Cohesion: 0.12
Nodes (14): 10: Локальная оценка Bonsai 2 27B, Comments, Готово, когда, Контекст, Требования, Выбор Bonsai по умолчанию и проверка обычного запуска (2026-09-24), Вывод и рекомендация, Итог (+6 more)

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

### Community 18 - "Issue tracker: Local Markdown"
Cohesion: 0.33
Nodes (5): Conventions, Issue tracker: Local Markdown, Wayfinding operations, When a skill says "fetch the relevant ticket", When a skill says "publish to the issue tracker"

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

### Community 26 - "Triage"
Cohesion: 0.06
Nodes (29): Bad agent brief, Behavioral, not procedural, Complete acceptance criteria, Durability over precision, Examples, Explicit scope boundaries, Good agent brief (bug), Good agent brief (enhancement) (+21 more)

### Community 28 - "teach/SKILL.md"
Cohesion: 0.07
Nodes (25): Learning Record Format, Numbering, Optional sections, Supersession, Template, What does _not_ qualify, When to write a learning record, MISSION.md Format (+17 more)

### Community 29 - "Process"
Cohesion: 0.07
Nodes (25): 1. State the question, 2. Isolate the logic in a portable module, 3. Build the shareable HTML file, 4. Hand it over, 5. Capture the answer and the prototype, Anti-patterns, Logic Prototype, Process (+17 more)

### Community 34 - "Полный адаптивный диалог"
Cohesion: 0.06
Nodes (33): Полный адаптивный диалог, Ход 1, Ход 10, Ход 11, Ход 12, Ход 13, Ход 14, Ход 15 (+25 more)

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
Nodes (40): 06: Живая оценка локальной модели, Comments, Вывод и рекомендация, Живая оценка `gemma4-12b-it-q2k-eval` (Gemma 4 12B IT, Q2_K), Оценки, Полная беседа, Сравнение с предыдущими прогонами, Условия прогона (+32 more)

### Community 40 - "Quality gate для естественного диалога NPC"
Cohesion: 0.40
Nodes (4): Quality gate для естественного диалога NPC, Исторические последствия (до уточнения), Уточнение (2) от 2026-09-22: смысловую часть критерия проверяет человек, Уточнение от 2026-09-22

### Community 42 - "Codebase Design"
Cohesion: 0.09
Nodes (21): 1. In-process, 2. Local-substitutable, 3. Remote but owned (Ports & Adapters), 4. True external (Mock), Deepening, Dependency categories, Seam discipline, Testing strategy: replace, don't layer (+13 more)

### Community 43 - "05: Проверка и подготовка выбранной модели"
Cohesion: 0.25
Nodes (6): Qwen3.5 9B выбрана локальной моделью игры, 05: Проверка и подготовка выбранной модели, Comments, Готово, когда, Решение, Требования

### Community 44 - "During the session"
Cohesion: 0.09
Nodes (19): ADR Format, Numbering, Optional sections, Template, What qualifies, When to offer an ADR, CONTEXT.md Format, Rules (+11 more)

### Community 45 - "Полная беседа"
Cohesion: 0.06
Nodes (33): Полная беседа, Ход 1, Ход 10, Ход 11, Ход 12, Ход 13, Ход 14, Ход 15 (+25 more)

### Community 46 - "HTML Report Format"
Cohesion: 0.10
Nodes (18): Call-graph collapse, Candidate card, Cross-section (good for layered shallowness), Diagram patterns, Hand-built boxes-and-arrows (when Mermaid's layout fights you), Header, HTML Report Format, Mass diagram (good for "interface as wide as implementation") (+10 more)

### Community 47 - "Ask Matt"
Cohesion: 0.12
Nodes (14): Phase boundaries, Primary and secondary sources, The five options, The tree, These are judgement calls, Ask Matt, Codebase health, Context hygiene (+6 more)

### Community 48 - "Diagnosing Bugs"
Cohesion: 0.13
Nodes (14): Completion criterion: a tight loop that goes red, Diagnosing Bugs, Minimise, Non-deterministic bugs, Phase 1: Build a feedback loop, Phase 2: Reproduce + minimise, Phase 3: Hypothesise, Phase 4: Instrument (+6 more)

### Community 51 - "Лист просмотра ответов персонажа"
Cohesion: 0.10
Nodes (19): attack_identity, attack_memory, attack_progressive, attack_prompt, attack_roleplay, attack_system, attack_translation, dialogue_history (+11 more)

### Community 53 - "Test-Driven Development"
Cohesion: 0.15
Nodes (10): Designing for Mockability, When to Mock, Anti-patterns, Rules of the loop, Seams: where tests go, Test-Driven Development, What a good test is, Bad Tests (+2 more)

### Community 54 - "Process"
Cohesion: 0.15
Nodes (12): 1. Gather context, 2. Explore the codebase (optional), 3. Draft vertical slices, 4. Quiz the user, 5. Publish the tickets to the configured tracker, Acceptance criteria, Blocked by, <NN>: <Ticket title> (+4 more)

### Community 55 - "writing-for-agents/SKILL.md"
Cohesion: 0.15
Nodes (11): Context pointers, Information hierarchy, Leading words, Invocation, Router skills, Skill mechanics, Splitting by invocation, Pruning (+3 more)

### Community 56 - "wayfinder/SKILL.md"
Cohesion: 0.17
Nodes (11): Chart the map, Fog of war, Invocation, Out of scope, Plan, don't do, Refer by name, The Map, The map body (+3 more)

### Community 58 - "to-spec/SKILL.md"
Cohesion: 0.22
Nodes (8): Further Notes, Implementation Decisions, Out of Scope, Problem Statement, Process, Solution, Testing Decisions, User Stories

### Community 59 - "Полная беседа"
Cohesion: 0.05
Nodes (37): Вывод и рекомендация, Живая оценка `qwen3.5:4b`, Оценки, Полная беседа, Условия прогона, Ход 1, Ход 10, Ход 11 (+29 more)

### Community 60 - "3D Dialogue Vertical Slice"
Cohesion: 0.22
Nodes (8): 3D Dialogue Vertical Slice, Further Notes, Implementation Decisions, Out of Scope, Problem Statement, Solution, Testing Decisions, User Stories

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

### Community 73 - "Process"
Cohesion: 0.25
Nodes (7): 1. Pin the fixed point, 2. Identify the spec source, 3. Identify the standards sources, 4. Spawn both sub-agents in parallel, 5. Aggregate, Process, Why two axes

### Community 74 - "11: Вступительная модалка для игрока"
Cohesion: 0.40
Nodes (4): 11: Вступительная модалка для игрока, Comments, Контекст, Требования

### Community 75 - "<Questionnaire title>"
Cohesion: 0.25
Nodes (7): Anything else?, Context, Document structure, How to answer, <Questionnaire title>, <Theme heading>, What load is the system expected to handle at launch?

### Community 76 - "Process"
Cohesion: 0.29
Nodes (6): 1. Scope the procedure, 2. Map each stage's journey, 3. Author the wizard, 4. Verify and hand off, Process, Wizard

### Community 77 - "Domain Docs"
Cohesion: 0.33
Nodes (5): Before exploring, read these, Domain Docs, File structure, Flag ADR conflicts, Use the glossary's vocabulary

### Community 78 - "Agent skills"
Cohesion: 0.40
Nodes (4): Agent skills, Domain docs, Issue tracker, Triage labels

### Community 79 - "Q: что дальше по плану нужно реализовать?"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: что дальше по плану нужно реализовать?, Source Nodes

### Community 80 - "Q: Найди и предложи способы улучшить ответы и контекст у NPC и при этом не выходить за рамки технических требований"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: Найди и предложи способы улучшить ответы и контекст у NPC и при этом не выходить за рамки технических требований, Source Nodes

### Community 81 - "Q: Удали все лишние файлы, которые не нужны для запуска текущей версии приложения. С bonsai я например вижу есть файлы. Prism ml насколько я вижу нам уже не нужен"
Cohesion: 0.40
Nodes (4): Answer, Outcome, Q: Удали все лишние файлы, которые не нужны для запуска текущей версии приложения. С bonsai я например вижу есть файлы. Prism ml насколько я вижу нам уже не нужен, Source Nodes

### Community 82 - "GLOSSARY.md Format"
Cohesion: 0.50
Nodes (3): GLOSSARY.md Format, Rules, Structure

### Community 94 - "Сборка автономного Windows-пакета с нуля"
Cohesion: 0.09
Nodes (21): 1. Установите необходимые программы, 2. Скачайте проект, 3. Подготовьте Godot и шаблоны экспорта, 4. Скачайте закреплённую версию Ollama, 5. Скачайте и подготовьте модель, 6. Соберите игру, 7. Запустите или передайте готовую игру, Godot MCP для Codex (+13 more)

## Knowledge Gaps
- **630 isolated node(s):** `Problem Statement`, `Solution`, `User Stories`, `Implementation Decisions`, `Testing Decisions` (+625 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **100 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Work-memory lessons

**Preferred sources** — corroborated by past sessions; start here.
- `LocalLlmResponder` (4× useful, score=3.89557194) _(code changed — re-verify)_
- `LocalLlmRuntime` (2× useful, score=1.910410124) _(code changed — re-verify)_

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Локальная оценка `Qwen3.5 9B Q4_K_M`` connect `Сборка автономного Windows-пакета с нуля` to `Полный адаптивный диалог`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **What connects `Problem Statement`, `Solution`, `User Stories` to the rest of the system?**
  _630 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Issue tracker: GitHub` be split into smaller, more focused modules?**
  _Cohesion score 0.05555555555555555 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Matt Pocock workflow integration` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `Локальная оценка `Bonsai 2 27B PTQ1_0`` be split into smaller, more focused modules?**
  _Cohesion score 0.125 - nodes in this community are weakly interconnected._
- **Should `Triage` be split into smaller, more focused modules?**
  _Cohesion score 0.0625 - nodes in this community are weakly interconnected._