# ZCode CLI Investigation

## Starting observation

ZCode Desktop 3.6.5 was observed spawning a process named `zcode-cli`. It is bundled with the app rather than exposed as a normal shell command.

This proves an internal runtime exists. It does **not** prove a supported external CLI contract exists.

## Objective

Determine whether T3 can interoperate with it without extracting credentials, bypassing auth, relying on renderer automation, or losing ZCode app-plan promotional economics.

## A. Observe process

Collect read-only:

- PID/PPID and parent;
- argv;
- cwd;
- child processes;
- open files;
- Unix sockets;
- TCP listeners/connections;
- lifecycle relative to ZCode sessions;
- app version.

Use `scripts/observe-zcode-cli.sh`.

Never include environment variable **values** in research artifacts.

## B. Locate launch/protocol code

Inspect `/Applications/ZCode.app` only for interoperability clues:

- spawn call and args;
- protocol names;
- JSON-RPC/WebSocket/gRPC/stdio/Unix socket signatures;
- lifecycle messages;
- version checks.

Do not copy credentials or attempt to bypass subscription controls.

## C. Classify transport

| Interface | Outlook |
|---|---|
| documented HTTP/WebSocket/JSON-RPC | excellent |
| stable stdio JSON | excellent |
| ACP/MCP-style protocol | excellent |
| structured Unix socket | good |
| CLI args + structured stdout | good |
| Electron-internal object coupling | fragile |
| UI automation / pixel parsing only | reject |

## D. Controlled reproduction

Only after the interface is understood:

1. use a disposable project;
2. launch through a supported ownership path where possible;
3. run a bounded read-only task;
4. observe start/stream/complete/stop;
5. restart the app and repeat.

## E. Economic validation

Compare identical bounded tasks:

A. normal ZCode desktop  
B. proposed T3/ZCode bridge

Record before/after plan quota and timestamps. If B is treated as generic API usage and loses the ZCode app bonus, the bridge may not be worth maintaining.

## GO

Build `ZCodeDriver` only if launch/transport is structured, auth remains ZCode-owned, quota benefit survives, failure is detectable, and changes remain provider-local.

## NO-GO

Reject if credentials must be extracted, renderer state is required, billing class changes, upgrades repeatedly break it, or core T3 must special-case ZCode.
