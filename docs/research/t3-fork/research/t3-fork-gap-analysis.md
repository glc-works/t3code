# T3 Fork Gap Analysis — executive summary

**Date:** 2026-08-07
**Upstream base:** `pingdotgg/t3code` @ `c471145e`
**Fork:** `glc-works/t3code`, branch `research/t3-fork-gap-analysis`
**Scope set by user:** work happens **in the fork, separate from headless-company-books**. ZCode investigation is **observe + classify only** (no prototyping).

## Headline

The package's central hypothesis is **correct and verified against source**: T3's `ProviderDriver` / `ProviderAdapter` boundary is exactly the right extension point, and a normal new driver needs **zero RED changes** (no orchestration, contract, or client-runtime edits). The fork should stay thin. The package's discipline (GREEN/YELLOW/RED budget, fail-closed, evidence-before-code) is sound and I recommend adopting it verbatim.

Of the three concrete candidate workstreams, only **one** (the OpenCode→Qwen path) is unambiguously available today; **one** is conditional on a benchmark we have not run; **one** is **NO-GO** on access-boundary grounds.

## Per-candidate verdicts

| candidate | verdict | one-line reason | detail |
|---|---|---|---|
| **Qwen via OpenCode (Q1)** | **ADOPT EXISTING PATH** | already shipped upstream; zero fork work | `t3-provider-change-map.md`, `qwen-route-benchmark-plan.md` |
| **Native QwenCodeDriver (Q2)** | **EXPERIMENTAL ONLY** (conditional) | only if Q1 is measured materially worse AND Qwen Code exposes a documented external harness protocol | `qwen-route-benchmark-plan.md` (acceptance thresholds defined) |
| **ZCodeDriver (ZCode bundled `zcode-cli`)** | **NO-GO** | MCP/stdio transport is structured, but the socket is token-gated internal IPC; reaching it requires credential extraction or launcher spoofing, both on the package's NO-GO list | `zcode-cli-evidence.md` |
| **Minimal sequential handoff** | **EXPERIMENTAL ONLY — prototype, measure, remove if it doesn't move** | correctly minimal in source design; the risk is accidental RED scope creep | `handoff-design-review.md` |

## The one finding that upgraded my read (Task C)

I went into Task C expecting to classify `zcode-cli` as "structured Unix socket, fragile." The static scan upgraded the transport: it is **MCP-over-stdio with `Content-Length` framing** (117 `mcp` / 76 `mcpServer` / 56 `initialize` references in `out/host/index.js`). On paper that is the package's "excellent" category.

**But** the same scan found the access boundary: the MCP socket is bound to `$TMPDIR/znr-<uuid>.sock`, gated by `--launcher-pid` + `--token-file .broker-token-<pid>-…`, and the host reaps any helper whose launcher is dead or whose token owner is "unrelated" (`isReapableOrphanHelper`). So a T3 bridge would have to counterfeit launcher identity to connect — which is forbidden by `03-…` §NO-GO. **The structured transport does not rescue this; the gating kills it.** This is the nuance the headline "MCP server" framing would have missed.

Self-observation caveat (recorded in the evidence file): this very session runs inside one of the `zcode-cli` processes in the observed tree, so the observation deliberately probed the *sibling root* (PID 1030) and read no env values, no `config.json`, no `broker-token-*` contents.

## What the fork should actually do (sequenced)

1. **Nothing structural yet.** Land this research package + these five findings on `research/t3-fork-gap-analysis` and leave it there as the reference. No code to `main`.
2. **Q1 first, as a smoke check.** Before any benchmarking, confirm `T3 → OpenCode → Qwen` actually works end-to-end through the fork (start session, read-only turn, stream, stop). If Q1 itself is broken, the rest is moot.
3. **Run the Q1-vs-direct benchmark** (`qwen-route-benchmark-plan.md`) only if you actually use Qwen through T3 enough to care. Pin a repo commit, run the read-only + implementation workloads 3× each peak/off-peak, fill the matrix, decide. **Default outcome: ADOPT Q1, document, close.**
4. **Re-open ZCode only if** ZCode ships `zcode-cli` as a documented external binary (real `--help`, stable `--port`/`--stdio`, published headless mode preserving plan economics). Until then it is out of scope and users should keep using ZCode Desktop directly (the `04-…` G1 option).
5. **Handoff prototype**, if wanted, per `handoff-design-review.md`: GREEN+YELLOW only, behind a setting, measured against the value test, removed if it doesn't move. No contracts in v1.

## Fork-maintenance posture (from `06-…`, endorsed)

- Keep one concern per feature branch; never mix provider work with workflow or branding.
- Track RED/YELLOW file count per feature. A feature that needs RED changes is a signal to stop, not a signal to refactor core.
- Record exact upstream base SHA + tag for any custom release.
- Generic SPI/reliability fixes may be upstreamable; ZCode internals and personal workflow features stay private. (Upstream `CONTRIBUTING.md` is closed to large unsolicited features.)

## Non-goals reaffirmed (do not build)

task DAG · durable scheduler · recursive autonomous delegation · distributed workers · a new model gateway · a second workflow database · a Gas Town/CAO clone inside T3 · credential extraction · auth bypass.

## Deliverables in this branch

- `research/t3-fork-gap-analysis.md` — this document
- `research/t3-provider-change-map.md` — Task A (source-backed SPI trace)
- `research/zcode-cli-evidence.md` — Task C (transport classification + NO-GO)
- `research/qwen-route-benchmark-plan.md` — Task B (decision rule + matrix)
- `research/handoff-design-review.md` — Task D (prototype boundary)
- `evidence/` — raw `ps`/`lsof`/asar captures backing Task C
- `00..08-*.md` + `scripts/` + `templates/` — the original research package, preserved

## Status of open questions

| question | status |
|---|---|
| Does `T3 → OpenCode → Qwen` work end-to-end? | **NOT YET VERIFIED** — step 2 above |
| Is Q1 materially worse than direct Qwen Code on any axis? | **NOT MEASURED** — step 3 above |
| Does Qwen Code expose a documented external harness protocol? | **UNKNOWN** — the gate for Q2; cheapest check is `qwen-code --help` |
| Does ZCode expose a stable external contract? | **NO** (this pass) — internal, token-gated, unversioned |
| Is the minimal handoff worth keeping? | **UNMEASURED** — needs ~2 weeks of real use after prototype |

## Recommendation in one sentence

**Land the research, smoke-test Q1, and do not write a driver until a benchmark says you should — and never write a ZCodeDriver against the bundled `zcode-cli`.**
