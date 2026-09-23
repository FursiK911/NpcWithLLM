---
type: "architecture"
date: "2026-09-23T21:16:50.686259+00:00"
question: "How does the game select the local LLM provider and where is the runtime seam?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["LocalLlmConfig", "LocalLlmResponder", "LocalLlmRuntime", "Bonsai2PrismRuntime", "Main.tscn"]
---

# Q: How does the game select the local LLM provider and where is the runtime seam?

## Answer

LocalLlmConfig.tres selects a provider. LocalLlmResponder.GetRuntime creates LocalLlmRuntime for Ollama or Bonsai2PrismRuntime for Prism. Tests can still inject an ILocalLlmRuntime with Configure. Main.tscn uses the ordinary responder and therefore honors the configured default.

## Outcome

- Signal: useful

## Source Nodes

- LocalLlmConfig
- LocalLlmResponder
- LocalLlmRuntime
- Bonsai2PrismRuntime
- Main.tscn