# Provider Extension Map

## Discovery checklist

For every candidate harness determine:

- executable/runtime discovery;
- version/health probe;
- supported multiple instances;
- configurable binary/server URL;
- auth ownership;
- model/thinking controls;
- approval mode;
- structured event transport.

## Lifecycle checklist

A first-class provider should support or explicitly declare unsupported:

```text
start -> ready -> turn -> stream -> interaction -> completion
       -> interrupt -> stop -> resume/read/rollback
```

Prefer a structured protocol over terminal parsing.

## File pattern

Target shape:

```text
apps/server/src/provider/Drivers/QwenCodeDriver.ts
apps/server/src/provider/Layers/QwenCodeAdapter.ts

apps/server/src/provider/Drivers/ZCodeDriver.ts
apps/server/src/provider/Layers/ZCodeAdapter.ts
```

Then add the driver to the built-in registry and only add settings/client work that is truly required.

## Decision tree

```text
Stable structured harness protocol?
  yes -> native adapter attractive
  no  -> stable noninteractive CLI + structured output?
          yes -> process adapter possible
          no  -> existing T3 provider hosts it well?
                  yes -> use existing path
                  no  -> NO-GO for now
```

## Contract threshold

Do not promote a vendor-only concept into generic T3 contracts unless at least two providers need it or it is inherently cross-provider.
