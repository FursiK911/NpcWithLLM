---
type: "query"
date: "2026-09-23T00:34:47.195246+00:00"
question: "How do the current game profile, context, memory, history, and generation settings flow into the local model request?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["ContextBuilder", "LocalLlmResponder", "LocalLlmRuntime", "DialogueHistory", "NpcProfile", "NpcMemory"]
---

# Q: How do the current game profile, context, memory, history, and generation settings flow into the local model request?

## Answer

Expanded from the graph vocabulary: [context, memory, history, profile, config, runtime, responder, local, llm]. The scene Main.tscn uses LocalLlmResponder with NpcProfile and LocalLlmConfig resources. LocalLlmResponder calls ContextBuilder.Build with profile.ToPersona(), situation, NpcMemory, DialogueHistory, and the new player message; it passes the resulting messages to LocalLlmRuntime configured from LocalLlmConfig. Relevant source locations: Scripts/Dialogue/ContextBuilder.cs:L11, Scripts/Dialogue/LocalLlmResponder.cs:L77, Scripts/Dialogue/LocalLlmRuntime.cs:L33, Scripts/Dialogue/NpcProfile.cs:L30.

## Outcome

- Signal: useful

## Source Nodes

- ContextBuilder
- LocalLlmResponder
- LocalLlmRuntime
- DialogueHistory
- NpcProfile
- NpcMemory