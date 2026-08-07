# Minimal Sequential Handoff Design

## Problem

A useful multi-agent workflow is often sequential:

```text
Claude Architect -> Codex Implementer -> Claude Reviewer -> Codex Fixer
```

The user should not need to manually recreate context each time.

## Smallest feature

Implement **human-triggered handoff**, not autonomous delegation.

```text
Thread A
  -> user clicks/commands Handoff
  -> choose destination provider/role
  -> T3 creates inspectable handoff context
  -> Thread B starts with provenance + objective + selected evidence
```

Suggested payload concept:

```json
{
  "handoffVersion": 1,
  "sourceThreadId": "...",
  "sourceTurnId": "...",
  "sourceCheckpoint": "...",
  "destinationRole": "implementer",
  "objective": "...",
  "evidence": [
    {"type":"diff","ref":"..."},
    {"type":"file","path":"..."}
  ]
}
```

Prototype this without new durable core semantics if possible. Promote it into contracts/events only after the interaction proves valuable.

## Non-goals

No recursive delegation, scheduler, DAG, worker pool, auto-merge, or invisible subagents.

## Value test

Keep the feature only if it reduces repeated prompting, wrong-branch handoffs, lost provenance, or reviewer uncertainty about the exact commit/diff.
