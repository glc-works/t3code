# Qwen route benchmark plan (Task B)

**Date:** 2026-08-07
**Status:** plan only. **No benchmark has been run.** Per the user's scope decision and the charter's "evidence before implementation," a native `QwenCodeDriver` is *not* recommended until Q1 (the existing path) is measured to be materially worse.

## The three routes (from `04-…`)

| id | route | status in T3 today |
|---|---|---|
| **Q1** | `T3 → OpenCode → Qwen Token Plan` | **AVAILABLE NOW.** `OpenCodeDriver.ts` + `OpenCodeAdapter.ts` ship upstream. Zero fork work. |
| **Q2** | `T3 → Qwen Code → Token Plan` (native driver) | hypothetical — 3 GREEN files + 3 YELLOW (see `t3-provider-change-map.md`) |
| **Q3** | `T3 → raw OpenAI/Anthropic-compatible model API` | **out of scope.** T3 is a harness control surface; owning the tool loop would duplicate mature coding harnesses (`04-…` Q3). |

## Decision rule (from `04-…` Q2)

> Justify Q2 only if Q1 has a measurable gap in **credits, caching, reliability, approvals, continuation, or quality**.

Each axis needs a number, not an impression. "Felt slower" is not evidence.

## Benchmark design

### Workload

Pin **one fixed upstream repo commit** of a small, real codebase (e.g. the headless-company-books repo at a known SHA, or a public toy) and run **two kinds of task**:

1. **Read-only workload** (deterministic) — "summarize the posting seam; identify the contract tests." Same prompt, same repo state, every run. This isolates *credits/cache/latency* from *quality*.
2. **Implementation workload** (rubric-scored) — "add a no-op endpoint at `/v1/ping` returning `{ok:true}`." Scored on: did it compile, did it pass `cargo clippy -D warnings`, did it touch only the requested files, did it follow existing conventions. Same scoring rubric for every route.

### Matrix

Run each cell ≥3 times (peak and off-peak for the credit-sensitive ones, since Qwen Token Plan has off-peak promotions):

| route | quality (rubric 0–4) | plan credits used | cached tokens (if exposed) | request/tool calls | files read | failures / N | elapsed | complexity (fork lines) |
|---|---|---|---|---|---|---|---|---|
| Qwen Code direct (baseline) | | | | | | | | 0 |
| **Q1:** T3 → OpenCode → Qwen | | | | | | | | **0 (shipped)** |
| Q2: native driver (build only if Q1 loses) | | | | | | | | ~3 GREEN + 3 YELLOW |

### Evidence fields (per `07-…`)

date · T3 fork SHA · macOS/build · OpenCode version · Qwen Code version · model id · **auth category** (not the secret) · workspace commit · exact prompt · result · **plan credit / quota delta**.

### Acceptance for Q2

Q2 is justified only if Q1 is **materially** worse on at least one axis *and* the gap is not fixable inside the OpenCode adapter:

- **Credits/quota:** Q1 uses ≥1.3× the credits of direct Qwen Code for the same workload, consistently across peak/off-peak. (A 30% gap is a real economic signal; 5% is noise.)
- **Caching:** Q1 does not benefit from Qwen's prompt cache while direct does, AND the cache hit rate is material (≥20% of input tokens).
- **Reliability:** Q1 fails or drops the session >5% of runs where direct succeeds.
- **Approvals / continuation:** Q1 cannot surface Qwen-specific approval or continuation primitives that direct exposes, AND those primitives are actually used in our workflows.
- **Quality:** Q1's implementation rubric score is ≥1 point lower on a 0–4 scale, consistently.

If none of those thresholds are met: **ADOPT EXISTING PATH (Q1).** Document the measurement in `evidence/qwen-route-benchmark-<date>.csv` and close the question.

## Sequencing

1. **First:** confirm OpenCode configured for Qwen actually works end-to-end through T3 (start session, read-only turn, stream, stop). This is a precondition — if Q1 itself is broken, the benchmark is moot.
2. **Then:** run the read-only workload Q1 vs direct Qwen Code, 3× each, peak and off-peak. Fill the credits/cached/latency cells.
3. **Then:** run the implementation workload Q1 vs direct, 3× each, score with the rubric.
4. **Only if** the acceptance thresholds above trigger: prototype Q2 as 3 GREEN files, re-run the matrix, and compare.
5. **Record** a decision (`templates/decision-record.md`) with the measured numbers.

## Non-goal

Do not benchmark Q3 (raw model API). The charter excludes T3 from owning the tool loop.

## Open question (flag, don't solve)

Qwen Code's own harness protocol — does it expose a **stable stdio/JSON-RPC/MCP external surface** the way Claude Code and OpenCode do? If yes, Q2 is a normal GREEN/YELLOW driver. If no (if it's an internal socket the way `zcode-cli` is — see Task C), Q2 collapses to NO-GO for the same reasons. **Confirm this before building Q2.** The cheapest check: run `qwen-code --help` (or whatever the binary is) and look for a documented `--port` / `--stdio` / `--listen` mode and a published schema. That single command is the gate.
