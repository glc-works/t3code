# T3 Fork Research Package

**Prepared:** 2026-08-07  
**Upstream:** `pingdotgg/t3code`

This package is intended to be copied into a T3 fork (for example under `docs/research/t3-fork/`) and then handed to a coding/research agent.

## Executive recommendation

Keep the fork **thin**. T3 already has the correct extension boundary for new coding harnesses:

```text
ProviderDriver
  -> ProviderAdapter
  -> canonical ProviderRuntimeEvent
  -> existing event-sourced orchestration
  -> web / desktop / mobile
```

Do not fork orchestration merely to add Qwen, GLM, or ZCode.

Recommended order:

1. Preserve upstream architecture and establish cheap upstream sync.
2. Benchmark `T3 -> OpenCode -> Qwen` before writing a native Qwen driver.
3. Investigate ZCode's bundled `zcode-cli` read-only.
4. Build a `ZCodeDriver` only if its interface is structured, stable, auth-safe, and preserves ZCode app-plan quota/promo behavior.
5. Consider a small **human-triggered sequential handoff** feature.
6. Stop before building a task DAG, scheduler, Gas Town clone, or CAO clone inside T3.

## Contents

- `00-research-charter.md`
- `01-t3-architecture-baseline.md`
- `02-provider-extension-map.md`
- `03-zcode-cli-investigation.md`
- `04-qwen-glm-integration-options.md`
- `05-minimal-handoff-design.md`
- `06-fork-maintenance-strategy.md`
- `07-test-and-evidence-plan.md`
- `08-gap-analysis-agent-prompt.md`
- `templates/evidence-matrix.csv`
- `templates/decision-record.md`
- `scripts/observe-zcode-cli.sh`

## Primary upstream references

- https://github.com/pingdotgg/t3code
- https://github.com/pingdotgg/t3code/blob/main/AGENTS.md
- https://github.com/pingdotgg/t3code/blob/main/docs/internals/overview.md
- https://github.com/pingdotgg/t3code/blob/main/docs/internals/providers.md
- https://github.com/pingdotgg/t3code/blob/main/apps/server/src/provider/ProviderDriver.ts
- https://github.com/pingdotgg/t3code/blob/main/apps/server/src/provider/Services/ProviderAdapter.ts
- https://github.com/pingdotgg/t3code/blob/main/apps/server/src/provider/builtInDrivers.ts

The public architecture explicitly says provider-specific complexity belongs at the adapter boundary and that a normal new driver should not require orchestration, contract, or client changes.
