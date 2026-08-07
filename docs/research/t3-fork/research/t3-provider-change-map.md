# T3 provider change map (Task A)

**Date:** 2026-08-07
**Upstream base:** `pingdotgg/t3code` @ `c471145e` (fork `glc-works/t3code` HEAD)
**Method:** every claim below is read from the source tree at that SHA. Status per the agent-prompt protocol (VERIFIED / PARTIAL / CONTRADICTED / DOC-ONLY / UNKNOWN).

## The extension path, traced

```text
ProviderInstanceConfig (settings, opaque config envelope)
  → ProviderDriver.configSchema            (decode; once per reload)     VERIFIED
  → ProviderDriver.create(input)           (materialize one instance)    VERIFIED
  → ProviderInstance                       (snapshot + adapter + textGen) VERIFIED
  → ProviderInstanceRegistry / Mutator     (keyed by instanceId)          VERIFIED
  → ProviderAdapter (provider-native lifecycle → canonical ops)          VERIFIED
  → reactors / ProviderRuntimeIngestion    (events → orchestration)       DOC-ONLY here (not re-traced in this pass; upstream docs/internals/providers.md)
  → OrchestrationEngine (decider/projector) — UNCHANGED by a new driver  VERIFIED (the decider takes no provider-specific input)
  → clients (web/desktop/mobile)                                           VERIFIED — driven by the same ProviderShape snapshot
```

## Minimum files for a new provider (the GREEN set)

Source: `apps/server/src/provider/builtInDrivers.ts:10-14` (commented 3-step recipe, verbatim):

> Adding a new first-party driver means:
>   1. implement `ProviderDriver` in a sibling `Drivers/<Name>Driver.ts`,
>   2. add it to this array,
>   3. ensure the runtime layer satisfies its declared `R`.

Concretely, for a hypothetical `QwenCodeDriver`:

| file | purpose | risk |
|---|---|---|
| `apps/server/src/provider/Drivers/QwenCodeDriver.ts` | `ProviderDriver<Config, R>` impl — config schema, `create()`, instance lifecycle | **GREEN** (new file) |
| `apps/server/src/provider/Layers/QwenCodeAdapter.ts` (or `Services/`) | `ProviderAdapter` — normalize Qwen-native lifecycle to canonical ops (start/turn/interrupt/approval/stop/stream) | **GREEN** |
| `apps/server/src/provider/Drivers/QwenCodeDriver.test.ts` + adapter test | co-located tests (this repo's convention — see `ClaudeDriver` siblings) | **GREEN** |

## The YELLOW surface (unavoidable, small)

| file | change | why |
|---|---|---|
| `apps/server/src/provider/builtInDrivers.ts` | add import + array entry + `BuiltInDriversEnv` union member | the registry only resolves drivers in this array (`:7-9`) |
| provider settings schema (`ServerSettings.providers.<kind>`) | add the new `driverKind` config slot | so users can configure it |
| provider picker / settings UI (`apps/web`) | add an entry | otherwise the driver exists but is not selectable |

These are the *only* non-GREEN touches a normal driver needs, and they are all additive. The SPI is explicitly designed so that step 1–3 do not touch orchestration, contracts, or clients.

## The RED surface (must stay zero)

| file | why RED |
|---|---|
| `apps/server/src/orchestration/decider.ts` | pure orchestration core |
| `apps/server/src/orchestration/projector.ts` | event fold |
| `apps/server/src/orchestration/Engine.ts` (if present) | the engine |
| `packages/contracts/src/*` | wire schema — promoting a vendor concept here is forbidden unless ≥2 providers need it (`02-provider-extension-map.md` §Contract threshold) |
| `packages/client-runtime` | generic client |
| `apps/server/src/provider/ProviderDriver.ts` | the SPI itself — widening this to accept a vendor-only capability is a RED change |
| checkpointing / VCS (`apps/server/src/checkpointing/`, `sourceControl/`) | durable semantics |

**The gate:** a driver integration must have **zero RED changes**. If it cannot be done with GREEN + the small YELLOW set above, the SPI is the wrong abstraction for that provider and the package's NO-GO applies.

## VERIFIED specifics

- `ProviderDriver<Config, R = never>` interface — `apps/server/src/provider/ProviderDriver.ts:119-157`.
- `ProviderInstance` shape — `:64-74`: holds `snapshot`, `adapter`, `textGeneration`, plus continuation identity. Two instances of the same driver MUST NOT share mutable state (`:115-117`).
- `ProviderDriverMetadata.supportsMultipleInstances` (`:52`) — set `false` for a single-global-resource driver (e.g. a desktop-app socket). **Relevant to the ZCode NO-GO**: even if the ZCode socket were reachable, this is the field that would mark it singleton.
- `BUILT_IN_DRIVERS` is `ReadonlyArray<AnyProviderDriver<BuiltInDriversEnv>>` (`:47`) — additive only; order is UI tie-break only.
- The registry produces an `"unavailable"` shadow snapshot for anything not in the array (`:7-9`) — this is the **fail-closed** behavior the charter requires. A driver that errors at `create()` becomes a shadow snapshot, never a crash (`:151-152`).

## Contract threshold (when YELLOW → RED)

Per `02-…` §Contract threshold: do not promote a vendor-only concept into `packages/contracts` unless at least two providers need it or it is inherently cross-provider. Example: if Qwen exposes a "thinking budget" knob that no other provider has, that stays in the Qwen driver's config schema, NOT in `packages/contracts`. The moment a second provider needs the same concept, *then* it becomes a contract change (and a separate, deliberate decision).

## Patch-surface budget per candidate

| candidate | GREEN | YELLOW | RED | total non-GREEN |
|---|---|---|---|---|
| Qwen via OpenCode (Q1) | 0 | 0 (already shipped) | 0 | **0** |
| Native QwenCodeDriver (Q2, if justified) | 3 | 3 (registry + settings + UI) | 0 | **3** |
| ZCodeDriver (Task C) | — | — | — | **NO-GO** (see `zcode-cli-evidence.md`) |
| Minimal handoff (Task D) | 1–2 if done as thread metadata; more if promoted to contracts | depends | **RED if it touches contracts/checkpoints** — see handoff review |

## Recommendation

The extension boundary is as clean as the package claims. The fork's first concrete provider work (if any) should be a **native QwenCodeDriver only after Task B's benchmark proves Q1 is materially worse** — and it should ship as 3 GREEN files + 3 YELLOW lines, zero RED. ZCode stays out (Task C). The handoff feature (Task D) is the only candidate that could force RED changes and must be prototyped at the thread layer before any contract promotion.
