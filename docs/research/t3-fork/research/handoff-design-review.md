# Handoff design review (Task D)

**Date:** 2026-08-07
**Source design:** `05-minimal-handoff-design.md` (human-triggered Architect → Implementer → Reviewer)
**Scope:** design review only. **No code.** No scheduler, no DAG, no autonomous delegation (per `05-…` §Non-goals).

## Verdict on the source design

The `05-…` design is correctly minimal and I endorse its shape: **human-triggered, not autonomous**. The payload sketch is sound. The single most important sentence in the package is `05-…`'s closing instruction:

> Prototype this without new durable core semantics if possible. Promote it into contracts/events only after the interaction proves valuable.

That is the right discipline. The risk is that "minimal handoff" quietly becomes a contracts/checkpoint change (RED), which is exactly what the maintenance strategy (`06-…`) says to avoid. This review is about pinning the line between the prototype (GREEN/YELLOW) and the promoted feature (RED).

## What the prototype should reuse vs. create

| concept | reuse? | where it lives in T3 today |
|---|---|---|
| thread identity | **reuse** | existing `ThreadId` |
| turn boundary | **reuse** | existing `TurnId` |
| checkpoint (the snapshot of repo state at a turn) | **reuse** | `apps/server/src/checkpointing/` — every turn already ends on a hidden git ref |
| provenance (which thread/turn/checkpoint a new thread was spawned from) | **create** as **thread metadata**, not a new event type |
| objective + selected evidence (the handoff payload) | **create** as the **first user message** of the destination thread, with a typed prefix |

The trick is: a handoff is *not a new orchestration concept*. It is **(a) read access to thread A's last checkpoint + (b) a new thread B seeded with that context.** Both primitives already exist. The prototype should be expressible as:

```
[user clicks Handoff on thread A]
  → server reads thread A's current checkpoint (existing API)
  → server creates thread B (existing API)
  → server posts the first message to thread B (existing API), formatted as:
       "[Handoff from <threadA>@<checkpoint>]\nObjective: <user-typed>\nEvidence:\n  - <diff ref>\n  - <file path>\n"
  → thread B starts with normal context
```

No new event. No new contract. No new durable schema.

## Payload sketch (refined from `05-…`)

`05-…` proposes a structured JSON payload. **For the prototype, I'd render it as a human+machine-readable first message instead**, for two reasons:

1. It works *today* with no contract change — every provider accepts a first user message.
2. The destination agent reads it as context, not as a typed RPC, which is how these workflows actually behave (the implementer doesn't `JSON.parse` a handoff; it reads prose).

If the prototype proves the workflow, *then* promote to the structured payload + a typed `ThreadHandoff` record — at which point it's a deliberate YELLOW→RED decision, not an accident.

Suggested first-message template (prototype):

```
[Handoff]
From: thread <A-id>, turn <turn-id>, checkpoint <ref>
Role requested: implementer
Objective: <one line, user-typed>

Context:
- <diff or file ref chosen by user>
- <diff or file ref chosen by user>

Instructions:
- Treat the above as the source of truth for this thread.
- Do not modify files outside the objective without asking.
```

## Value test (from `05-…`)

> Keep the feature only if it reduces repeated prompting, wrong-branch handoffs, lost provenance, or reviewer uncertainty about the exact commit/diff.

Operationalize each:

- **repeated prompting** — count how many times the user has to re-paste the same context across two threads today vs. with the handoff button.
- **wrong-branch handoffs** — count git-checkout mistakes during a multi-agent session.
- **lost provenance** — can the reviewer, 24h later, recover which thread/checkpoint produced this work? Today (without handoff) the answer is usually "no"; with the prototype it should be "yes, it's in the first message."
- **reviewer commit/diff uncertainty** — does the reviewer know the exact diff to look at?

If after ~2 weeks of real use none of these moved, **remove the feature**. The charter's stop-conditions apply.

## RED lines (what NOT to do in the prototype)

- do **not** add a `ThreadHandoff` event to the orchestration decider/projector.
- do **not** add a `handoff` field to `packages/contracts`.
- do **not** touch checkpoint internals — read the existing checkpoint ref, don't change how checkpoints are made.
- do **not** add an auto-chain ("handoff to reviewer automatically when implementer finishes"). That's autonomous delegation, which `05-…` explicitly excludes.
- do **not** add invisible subagents. The destination thread is a first-class, visible thread in the inbox, same as any other.

## Patch-surface budget (prototype)

| file | risk |
|---|---|
| new `apps/server/src/.../handoff.ts` (read checkpoint + create thread + post message) | **GREEN** |
| a UI button + destination-picker modal | **YELLOW** (web UI) |
| a settings flag to enable/disable | **YELLOW** (settings) |
| **no contract / decider / checkpoint / client-runtime changes** | **(RED = 0)** |

If a later promotion to typed events happens, it becomes a separate Issue with its own RED assessment and the maintenance-strategy rebase-discipline applies.

## Recommendation

**EXPERIMENTAL ONLY — prototype as described above, behind a setting, measure against the value test, and remove if it doesn't move.** Do not promote to contracts in the first iteration. This keeps the fork within its GREEN+YELLOW budget and respects the maintenance strategy.

The single biggest design risk to watch: scope creep from "handoff" to "workflow engine." The `05-…` non-goals list is the guardrail — re-read it every time the feature tempts a new capability.
