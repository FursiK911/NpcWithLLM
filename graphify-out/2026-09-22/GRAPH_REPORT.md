# Graph Report - .  (2026-09-22)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 56 nodes · 81 edges · 10 communities (7 shown, 3 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `bd988884`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Main
- MockChatResponder
- template.sh
- template.sh script
- .SubmitMessage
- hitl-loop.template.sh
- banner
- NpcWithLLM.csproj
- finish

## God Nodes (most connected - your core abstractions)
1. `Main` - 18 edges
2. `template.sh script` - 11 edges
3. `MockChatResponder` - 6 edges
4. `warn()` - 5 edges
5. `finish()` - 5 edges
6. `ChatResponder` - 5 edges
7. `_clear()` - 4 edges
8. `banner()` - 4 edges
9. `hitl-loop.template.sh script` - 3 edges
10. `stage()` - 3 edges

## Surprising Connections (you probably didn't know these)
- `Main` --references--> `ChatResponder`  [EXTRACTED]
  Scripts/Main.cs → Scripts/ChatResponder.cs
- `MockChatResponder` --inherits--> `ChatResponder`  [EXTRACTED]
  Scripts/MockChatResponder.cs → Scripts/ChatResponder.cs

## Import Cycles
- None detected.

## Communities (10 total, 3 thin omitted)

### Community 0 - "Main"
Cohesion: 0.18
Nodes (7): bool, Button, Label, Node3D, RichTextLabel, Main, TextEdit

### Community 1 - "MockChatResponder"
Cohesion: 0.20
Nodes (6): double, Node, ChatResponder, MockChatResponder, string, Task

### Community 2 - "template.sh"
Cohesion: 0.43
Nodes (4): open_url(), set_secret(), set_var(), warn()

### Community 3 - "template.sh script"
Cohesion: 0.33
Nodes (6): ask(), ask_secret(), say(), template.sh script, step(), write_env()

### Community 5 - "hitl-loop.template.sh"
Cohesion: 0.83
Nodes (3): capture(), hitl-loop.template.sh script, step()

### Community 6 - "banner"
Cohesion: 0.50
Nodes (4): banner(), _clear(), pause(), stage()

## Knowledge Gaps
- **2 isolated node(s):** `net8.0`, `Godot.NET.Sdk/4.7.2`
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Main` connect `Main` to `.FinishRequest`, `MockChatResponder`, `.SubmitMessage`?**
  _High betweenness centrality (0.221) - this node is a cross-community bridge._
- **Why does `ChatResponder` connect `MockChatResponder` to `Main`?**
  _High betweenness centrality (0.136) - this node is a cross-community bridge._
- **What connects `net8.0`, `Godot.NET.Sdk/4.7.2` to the rest of the system?**
  _2 weakly-connected nodes found - possible documentation gaps or missing edges._