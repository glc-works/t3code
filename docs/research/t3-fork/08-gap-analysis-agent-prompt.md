# Agent Prompt — T3 Fork Gap Analysis

You are auditing a private fork of `pingdotgg/t3code`.

Read this entire research package first. Treat it as hypotheses, not truth.

## Rule 1: evidence before code

Do not implement until you produce source-backed evidence.

For every material claim provide:

- repo/ref;
- file path;
- symbol/function/type;
- line range;
- status: VERIFIED / PARTIAL / CONTRADICTED / DOC-ONLY / UNKNOWN;
- consequence for the fork.

## Task A — provider extension trace

Trace the actual path:

```text
provider configuration
-> ProviderDriver registry
-> ProviderInstance
-> ProviderAdapter
-> ProviderService
-> ProviderCommandReactor
-> ProviderRuntimeIngestion
-> orchestration event/projection
-> clients
```

List the minimum files required for a new provider.

## Task B — Qwen

Compare:

1. existing OpenCode provider configured for Qwen;
2. possible native Qwen Code driver.

Do not recommend a native driver unless there is a stable machine-readable Qwen Code interface and a measurable benefit.

## Task C — ZCode

The machine may run ZCode Desktop with an internal `zcode-cli` subprocess.

Allowed: argv, parent/child mapping, open files/sockets, app-bundle code references, protocol identification, disposable read-only tests.  
Forbidden: credential extraction, auth bypass, copying tokens, patching binaries, circumventing plan/quota enforcement.

Determine launch mechanism, transport, lifecycle, auth ownership, upgrade stability, and plan-quota classification.

If fragile, recommend NO-GO.

## Task D — minimal handoff

Design only a human-triggered Architect -> Implementer -> Reviewer handoff using existing thread/checkpoint/event concepts. Do not design a scheduler or task DAG.

## Fork impact classes

Tag every proposed change:

- GREEN: new provider-local file;
- YELLOW: shared provider registry/settings/UI;
- RED: orchestration/contracts/client-runtime/checkpoint core.

Provider integrations should have no RED changes unless unavoidable.

## Deliverables

Create:

- `research/t3-fork-gap-analysis.md`
- `research/t3-provider-change-map.md`
- `research/zcode-cli-evidence.md`
- `research/qwen-route-benchmark-plan.md`
- `research/handoff-design-review.md`

Conclude separately for Qwen, ZCode, and handoff with one of:

- ADOPT EXISTING PATH
- BUILD THIN PROVIDER
- EXPERIMENTAL ONLY
- NO-GO
