# Test and Evidence Plan

## Evidence fields

Record for every result:

- date;
- T3 upstream/fork refs;
- macOS/T3 build;
- harness version;
- model;
- auth category (not secret value);
- workspace commit;
- exact test prompt;
- result;
- plan credit/quota delta when relevant.

## Provider acceptance

1. missing provider fails cleanly;
2. health probe works;
3. start session;
4. read-only turn;
5. normalized streaming;
6. interrupt;
7. approvals/input supported or capability-disabled;
8. stop;
9. restart does not corrupt T3 state;
10. checkpoint/diff works;
11. rollback is correct or disabled;
12. multiple instances do not unintentionally share mutable state.

## ZCode-specific

- app closed -> fail closed;
- app running -> discover runtime;
- app restart -> rediscover;
- version mismatch -> visible diagnostic;
- no secrets in logs;
- app-plan quota before/after recorded;
- promo/off-peak classification matches normal ZCode when claimed.

## Qwen benchmark

Run identical bounded tasks via:

A. Qwen Code direct  
B. T3 -> OpenCode -> Qwen  
C. native driver only if built

Measure plan credits, cached tokens if exposed, request/tool counts, files inspected, failures, elapsed time, and quality rubric. Separate peak/off-peak runs when applicable.

## Regression boundary

A custom provider must not regress Claude Code, Codex, OpenCode, checkpointing, remote connections, or mobile/web compatibility.
