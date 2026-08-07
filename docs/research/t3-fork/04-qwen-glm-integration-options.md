# Qwen and GLM Integration Options

## Qwen

### Q1 — existing OpenCode path (default first)

```text
T3 -> OpenCode -> Qwen Token Plan
```

Pros: zero new T3 driver, cheap upstream sync, broad provider support.  
Cons: may lose Qwen Code-specific caching/statistics/session behavior.

### Q2 — native Qwen Code driver

```text
T3 -> Qwen Code -> Token Plan
```

Justify only if Q1 has a measurable gap in credits, caching, reliability, approvals, continuation, or quality.

### Q3 — raw OpenAI/Anthropic-compatible model API

Not preferred initially. T3 is a harness control surface; making it own the model tool loop would duplicate mature coding harnesses.

## GLM

### G1 — keep ZCode desktop separate

Best baseline if the app receives superior quota/off-peak benefits.

### G2 — OpenCode -> Z.ai/GLM

Technically simple; benchmark economics against ZCode app usage.

### G3 — T3 -> bundled ZCode runtime

Potentially best only if it preserves app-plan economics and exposes a structured stable interface.

## Required benchmark

| Route | Quality | Plan credits/quota | Cache | Tool fidelity | Reliability | Complexity |
|---|---:|---:|---:|---:|---:|---:|
| Qwen Code direct | | | | | | |
| T3 -> OpenCode -> Qwen | | | | | | |
| ZCode desktop -> GLM | | | | | | |
| T3 -> OpenCode -> GLM | | | | | | |
| T3 -> ZCode runtime | | | | | | |

Use fixed repo commit + fixed read-only workload first, then one implementation workload.
