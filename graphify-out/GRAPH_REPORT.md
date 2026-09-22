# Graph Report - NpcWithLLM  (2026-09-22)

## Corpus Check
- 124 files · ~78,727 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 146 nodes · 157 edges · 20 communities (15 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ff03897b`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Main
- MockChatResponder
- template.sh
- What You Must Do When Invoked
- Matt Pocock workflow integration
- hitl-loop.template.sh
- /graphify
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
- Project-local Godot MCP

## God Nodes (most connected - your core abstractions)
1. `Main` - 18 edges
2. `What You Must Do When Invoked` - 12 edges
3. `template.sh script` - 11 edges
4. `/graphify` - 10 edges
5. `Matt Pocock workflow integration` - 9 edges
6. `graphify reference: extra exports and benchmark` - 8 edges
7. `MockChatResponder` - 6 edges
8. `graphify reference: query, path, explain` - 5 edges
9. `Graphify integration` - 5 edges
10. `warn()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Main` --references--> `ChatResponder`  [EXTRACTED]
  Scripts/Main.cs → Scripts/ChatResponder.cs
- `MockChatResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/MockChatResponder.cs → Scripts/ChatResponder.cs

## Import Cycles
- None detected.

## Communities (20 total, 5 thin omitted)

### Community 0 - "Main"
Cohesion: 0.14
Nodes (8): bool, Button, InputEvent, Label, Node3D, RichTextLabel, Main, TextEdit

### Community 1 - "MockChatResponder"
Cohesion: 0.20
Nodes (6): double, Node, ChatResponder, MockChatResponder, string, Task

### Community 2 - "template.sh"
Cohesion: 0.22
Nodes (16): ask(), ask_secret(), banner(), _clear(), finish(), note(), open_url(), pause() (+8 more)

### Community 3 - "What You Must Do When Invoked"
Cohesion: 0.13
Nodes (15): Part A - Structural extraction for code files, Part B - Semantic extraction (parallel subagents), Part C - Merge AST + semantic into final extraction, Step 0 - GitHub repos and multi-path merge (only if a URL or several paths), Step 1 - Ensure graphify is installed, Step 2.5 - Video and audio (only if video files detected), Step 2 - Detect files, Step 3 - Extract entities and relationships (+7 more)

### Community 4 - "Matt Pocock workflow integration"
Cohesion: 0.14
Nodes (13): `code-review`, `diagnosing-bugs`, Graphify integration, `grill-with-docs`, `implement`, `improve-codebase-architecture` / `codebase-design`, Keeping the graph current, Matt Pocock workflow integration (+5 more)

### Community 5 - "hitl-loop.template.sh"
Cohesion: 0.83
Nodes (3): capture(), hitl-loop.template.sh script, step()

### Community 6 - "/graphify"
Cohesion: 0.20
Nodes (9): For /graphify add and --watch, For /graphify query, For the commit hook and native CLAUDE.md integration, For --update and --cluster-only, /graphify, Honesty Rules, Interpreter guard for subcommands, Usage (+1 more)

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
Cohesion: 0.50
Nodes (3): Consequences, Considered Options, Граница подключения локальной языковой модели

### Community 18 - "NpcWithLLM"
Cohesion: 0.40
Nodes (4): Godot MCP для Codex, NpcWithLLM, Направление проекта, Текущий статус

## Knowledge Gaps
- **62 isolated node(s):** `Текущий статус`, `Направление проекта`, `Godot MCP для Codex`, `Consequences`, `Usage` (+57 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Main` connect `Main` to `MockChatResponder`?**
  _High betweenness centrality (0.031) - this node is a cross-community bridge._
- **Why does `What You Must Do When Invoked` connect `What You Must Do When Invoked` to `/graphify`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `ChatResponder` connect `MockChatResponder` to `Main`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `Текущий статус`, `Направление проекта`, `Godot MCP для Codex` to the rest of the system?**
  _62 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Main` be split into smaller, more focused modules?**
  _Cohesion score 0.14035087719298245 - nodes in this community are weakly interconnected._
- **Should `What You Must Do When Invoked` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `Matt Pocock workflow integration` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._