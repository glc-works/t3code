# Research Charter

## Decision

Find the smallest maintainable changes that turn a private T3 fork into a better cockpit for heterogeneous native coding agents.

## Questions

1. Is `T3 -> OpenCode -> Qwen` already good enough?
2. Would a native Qwen Code driver materially improve Token Plan economics, caching visibility, approvals, continuation, or reliability?
3. Can ZCode's internal `zcode-cli` be controlled through a stable external interface?
4. Would that path preserve ZCode app-plan/off-peak/promotional quota classification?
5. What is the smallest useful Architect -> Implementer -> Reviewer handoff?
6. Which changes stay provider-local and which force core changes?

## Non-goals

Do not build yet:

- task DAG or durable scheduler;
- recursive autonomous delegation;
- distributed workers;
- a new model gateway;
- a second workflow database;
- a Gas Town/CAO clone inside T3;
- credential extraction or auth bypass.

## Principles

- **Native harness before raw model API.** Harness behavior matters.
- **Observe before controlling.** Especially for `zcode-cli`.
- **Provider complexity stays at the provider boundary.**
- **Evidence before implementation.** Pin refs, versions, exact tests, and quota deltas.
- **Fail closed.** An unavailable experimental provider must not damage generic T3 behavior.

## Stop conditions

Stop an integration if it:

- requires provider-specific logic in core orchestration;
- requires copying private credentials;
- loses the economic benefit of a subscription plan;
- breaks on routine app upgrades;
- depends on UI automation or terminal pixel scraping when no stable structured interface exists.
