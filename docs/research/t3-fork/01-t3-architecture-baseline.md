# T3 Architecture Baseline

## Shape

```text
web / desktop / mobile
        |
 authenticated Effect RPC WebSocket
        |
apps/server
  - event-sourced orchestration
  - provider registry/adapters
  - checkpointing / VCS
  - terminal / filesystem
        |
 native agent runtimes
```

T3's server owns execution. Provider processes, filesystem access, Git operations, and terminals run server-side.

## Orchestration invariant

Documented command path:

```text
typed command
-> OrchestrationEngine
-> pure decider
-> persisted events + projections in one SQL transaction
-> committed read model
-> queue-backed reactors
-> provider/checkpoint side effects
-> normalized runtime events
```

Do not bypass this with provider-specific UI state.

## Provider SPI

Current built-ins: Codex, Claude, Cursor, Grok, OpenCode.

A `ProviderDriver` owns typed config and creates a scoped `ProviderInstance`. The instance exposes a provider snapshot, runtime adapter, text-generation surface, and continuation identity.

A `ProviderAdapter` normalizes provider-native lifecycle into T3 operations such as:

- start session;
- send turn;
- interrupt;
- approval response;
- user-input response;
- stop/list/inspect sessions;
- read/rollback thread;
- stream canonical runtime events.

Upstream maintainer docs state that, in the common case, adding a provider means implementing a driver + adapter and registering it in `BUILT_IN_DRIVERS`, without changing orchestration/contracts/clients.

## Fork-risk zones

### GREEN — low conflict

- new driver file;
- new adapter file;
- provider-specific tests/docs.

### YELLOW — moderate conflict

- `builtInDrivers.ts`;
- provider settings schema;
- provider picker/settings UI.

### RED — expensive fork divergence

- orchestration contracts;
- decider/projector/engine;
- generic client runtime;
- checkpoint semantics.

A provider integration should have **zero RED changes** unless the gap analysis proves they are necessary.
