# Graphify integration

Graphify is the project's structural navigation index. It complements the Matt Pocock Skills; it does not replace them.

## Sources of truth and responsibilities

- **Graphify** describes implementation structure: classes, functions, imports, calls, inheritance, cross-file dependencies, communities, and paths between concepts.
- **`CONTEXT.md`** defines domain language and concepts. It is the source of truth for terminology; Graphify does not replace it.
- **ADRs in `docs/adr/`** record the reasons for important architectural decisions.
- **Matt Pocock Skills** control the development process: design, specification, ticket decomposition, implementation, TDD, diagnosis, review, and architecture work.

Use Graphify to find where to look. Use source code and tests to establish what is true. Use the Matt Pocock Skills to decide and control what to build.

Graphify evidence has limits:

- Treat `INFERRED` edges as hypotheses until source code confirms them.
- Treat `EXTRACTED` edges as structural evidence, not a complete behavior specification.
- Before changing code, read the real source files and tests identified by the graph.
- Make final behavior decisions from source, tests, `CONTEXT.md`, ADRs, and the active spec.

## When to use Graphify first

Start with a minimal Graphify query before broad raw-source exploration when the task:

- enters an unfamiliar subsystem;
- crosses multiple modules or has an uncertain blast radius;
- requires understanding existing architecture or a public seam/interface;
- involves a complex bug with an unclear execution path;
- asks how two systems, concepts, classes, or modules are connected; or
- proposes refactoring existing architecture.

Prefer the narrowest useful command, then inspect the real files it returns:

```text
graphify query "<question>"
graphify explain "<concept>"
graphify path "<concept A>" "<concept B>"
```

Do not invoke Graphify mechanically for an obvious local change when the files and dependency path are already known. This includes text changes, inspector tooltips, a known local method, or an obvious field in a known class.

## Matt Pocock workflow integration

### `grill-with-docs`

When designing a change in an existing or insufficiently familiar system:

1. Use Graphify to learn current structure before asking the user questions about facts the repository can answer.
2. Give the relevant graph paths, callers, communities, and possible blast radius to the grilling process.
3. Keep decisions with the user.
4. Record domain vocabulary in `CONTEXT.md` and architectural reasons in ADRs, not in Graphify.

Graphify answers: “How is it connected now?”

`grill-with-docs` answers: “How do we want it to work?”

### `to-spec`

For a spec about an existing system, use Graphify when needed to identify current seams, dependencies, and blast radius. Verify important claims in source code. Keep Graphify implementation details out of the spec unless they affect user behavior or an explicit implementation decision.

### `to-tickets`

Graphify may validate code dependencies during decomposition, but it must not replace the ticket blocking graph. A Graphify edge is a code relationship; a ticket blocking edge is a logical work dependency.

```text
Graphify graph = code
Ticket graph   = work
```

Keep the two graphs separate.

### `implement`

For one ticket:

1. Read the ticket and spec.
2. If the scope is unfamiliar or cross-module, run the smallest useful Graphify query, explain, or path.
3. Select a small set of real source files and read them.
4. Continue with the normal workflow: TDD where appropriate, typecheck/tests, code-review, and commit.

Graphify narrows the search; it does not replace local reading of the code being changed.

### `tdd`

Use TDD to shape testable vertical slices inside one ticket. Use Graphify only to locate the seam, callers, collaborators, and relevant tests when the slice is unfamiliar. Keep the red-green-refactor loop and test behavior through the agreed seam.

### `diagnosing-bugs`

Preserve the existing feedback loop:

```text
feedback loop → reproduce → minimise → hypotheses → instrumentation → fix → regression test
```

Graphify comes after a reproducible feedback loop exists. It can narrow execution/dependency paths, callers, neighboring systems, and the hypothesis space. Root cause must still be confirmed by runtime and source evidence.

### `improve-codebase-architecture` / `codebase-design`

Use Graphify as a source of candidates: God Nodes, highly connected nodes, communities, cross-community dependencies, surprising connections, and dependency paths. Centrality is a signal, not proof of an architectural smell.

Evaluate each candidate with `codebase-design`: module depth, interface, seam, locality, leverage, and the deletion test.

### `code-review`

Use Graphify during review only when the change touches a public seam, shared module, or potentially large or surprising blast radius. The review axes remain **Standards** and **Spec**; Graphify does not add a third independent review axis.

## Keeping the graph current

- The project post-commit hook performs the code-only incremental update after commits.
- For code changes outside a commit, use `graphify update .` when a current graph is useful.
- Document changes can require a separate Graphify update or rebuild; do not run a full rebuild when an incremental update is sufficient.
- If the graph reports a health warning or stale output, surface it and verify the affected source directly.

Do not infer architectural conclusions solely from degree, centrality, or community membership. They are navigation signals for source-based analysis.
