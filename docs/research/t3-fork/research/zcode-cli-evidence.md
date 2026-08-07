# zcode-cli evidence (Task C)

**Date:** 2026-08-07
**Observer:** Z Code agent (this session runs *inside* one of the observed `zcode-cli` processes — see Self-observation caveat below)
**ZCode.app version:** 3.6.5 (`dev.zcode.app`)
**macOS:** 26.5.2 (darwin arm64)
**Scope set by the user:** *Observe + classify only*. Do not prototype a bridge.

## TL;DR

**Recommendation: NO-GO** for a T3 `ZCodeDriver` against the bundled `zcode-cli`.

The transport is structured and parseable — **MCP-over-stdio with `Content-Length` framing**, which on paper is the package's "excellent" category. But the **access boundary is internal and ZCode-owned**: the MCP socket is bound to a UUID-named path in the runtime temp dir, gated by a `--launcher-pid` + `--token-file` (`broker-token-<pid>-…`) handshake, and the host actively *reaps* helper processes whose launcher is dead or whose token belongs to an unrelated owner (`isReapableOrphanHelper`). To connect, a T3 bridge would have to copy a broker token, spoof a launcher PID, or inject itself into the ZCode process tree — all three are explicitly forbidden by `03-zcode-cli-investigation.md` §NO-GO ("requires copying private credentials", "patching binaries", "circumventing plan/quota enforcement"). The structured transport does not rescue this; the gating does.

## Evidence (status tagged per the agent-prompt protocol)

### E1. Process topology — VERIFIED

Observed via `ps` + `lsof` (raw capture in `evidence/zcode-cli-observation-20260807-091308.txt`):

```
PID  986  ppid 1     ZCode                              (Electron main)
PID 1010  ppid 986   zcode-host-local-1                 (host bridge)
PID 1030  ppid 1010  zcode-cli                          (long-lived root worker)
PID 1031  ppid 1010  zcode-cli                          (sibling workers)
PID 1033  ppid 1010  zcode-cli
PID 1429  ppid 1010  zcode-cli
PID 2068  ppid 1030  zcode-cli                          (child workers of 1030)
PID 4701  ppid 1030  zcode-cli
… ~16 zcode-cli processes total, etl ~1d3h for the roots
```

`zcode-cli` is launched with **no argv** (the `command` column is empty after the name). That alone rules out a documented CLI flag surface: there is no `--port`, no `--help`, no `--stdio`. Configuration is handed to the process in-band (socket/token), not on the command line.

### E2. Transport — data plane — VERIFIED

`lsof -nP -a -p 1030 -i` shows 4 established outbound TCP sockets:

```
192.168.31.75:59030 -> 163.181.47.35:443   (ESTABLISHED)
192.168.31.75:58443 -> 39.97.141.140:443   (ESTABLISHED)
192.168.31.75:58426 -> 39.97.141.140:443   (ESTABLISHED)
192.168.31.75:59093 -> 163.181.47.35:443   (ESTABLISHED)
```

These are the **model API endpoints** (CN-allocated IPs, HTTPS). They are outbound-only; nothing listens for inbound from T3 here. Auth to these endpoints is owned by ZCode (the app holds the session credentials, not `zcode-cli` argv).

### E3. Transport — control plane — VERIFIED

PID 1030 holds:

- **FD 0/1/2** as anonymous unix socketpairs (parent↔child stdio).
- **~6 bi-directional pipe pairs** (e.g. FD 5/6).
- **7 named unix domain sockets** at `$TMPDIR/znr-<uuid>.sock` (e.g. `znr-65121f10-6dcd-4a99-8efd-d3369f26e6cb.sock`). UUID-named, recreated per runtime, **no stable address**.
- **~100+ anonymous unix socketpair** FDs (FDs 19..138) — fan-out to worker children.

None of these is a TCP listener. None has a stable, addressable name. They are IPC rendezvous points inside the process tree.

### E4. Wire protocol — VERIFIED (static, no execution)

`out/host/index.js` from `app.asar` (1.67 MB compiled bundle). String scan:

| token | count |
|---|---:|
| `mcpServer` | 76 |
| `McpServer` | 44 |
| `initialize` (MCP handshake) | 56 |
| `mcp` (case-insensitive total) | 117 |
| `Mcp` | 79 |
| `stdio` / `Stdio` | 22 / 11 |
| `Content-Length` / `content-length` | 2 |
| `createServer` | 3 |

**Classification: MCP-over-stdio with `Content-Length` framing** (the canonical MCP transport). ZCode *hosts* the MCP server (`mcpServer`, not `mcpClient` is the dominant orientation). On paper this is the package's "excellent" row.

### E5. Access boundary — VERIFIED, and this is the killer

From the same bundle, the helper-spawn / reap logic (function names preserved by the bundler):

- `extractHelperOwnerPid(command)` — parses `--launcher-pid <N>` or derives it from `--token-file .broker-token-<pid>-…`.
- `isReapableOrphanHelper(entry, ctx)` — returns `true` (i.e. *kill it*) when `entry.uid !== ctx.currentUid || entry.ppid !== 1 || … || !ctx.executablePaths.some(s => e.command.includes(s)) || <socket not in runtimeDir> || <launcher dead> || <token owner unrelated>`.
- `standaloneHelperExecutablePaths()` — the only paths considered legitimate helper images.
- The socket path is read from `--socket <path>` and validated to live **inside `runtimeDir`** (`isPathWithinDir`).

So the MCP socket is **only reachable by a process that:**
1. Runs as the same uid (fine),
2. was spawned by the ZCode launcher (so its `ppid` chain and `--launcher-pid` check out),
3. holds a `.broker-token-<launcher-pid>-…` file owned by that launcher,
4. uses a socket path the launcher placed in `runtimeDir`,
5. and whose executable image matches the whitelist (`Contents/MacOS/<AppName-without-.app>`).

A T3 bridge is none of those. To become one it would have to **copy a broker token, spoof a launcher PID, or inject a helper binary into the app bundle** — each of which is on the package's NO-GO list and would also break on every ZCode upgrade (the token format, socket path, and reap rules are all internal and unversioned).

### E6. Quota / plan economics — UNKNOWN (not measured)

We did **not** run the controlled reproduction (§D of `03-…`) because the user scoped this to observe-and-classify-only. So we have no before/after quota measurement for a hypothetical bridge. Given E5, we did not reach the economic test — the access boundary fails first.

## Self-observation caveat (important)

This very session is hosted by one of the `zcode-cli` processes in the observed tree (the controlling worker for `sess_0736664c-…`). The observation script deliberately probes the **long-lived sibling root (PID 1030)** rather than its own controlling PID, to avoid perturbing the live session, and it **does not** read environment-variable values, `~/.zcode/cli/config.json` (which holds the session token), or any `broker-token-*` file contents. The `lsof`/`strings` output above contains only file *names*, socket *device ids*, and bundle code — no credentials.

## Mapping to the package's GO / NO-GO table (`03-…`)

| Test (`03-…` §GO) | Result |
|---|---|
| launch/transport structured | ✅ MCP/stdio, structured |
| auth remains ZCode-owned | ❌ bridge must counterfeit launcher identity |
| quota benefit survives | ❓ unmeasured — but irrelevant given the auth failure |
| failure detectable | ❓ irrelevant |
| changes remain provider-local | ❌ requires touching ZCode internals or spoofing tokens |
| **GO gate** | **FAIL** |

| NO-GO trigger (`03-…` §NO-GO) | Hit? |
|---|---|
| credentials must be extracted | **YES** (broker token) |
| renderer state required | no |
| billing class changes | unknown, likely (a bridged process is not the desktop client) |
| upgrades repeatedly break it | **YES** (token format, socket path, reap rules unversioned) |
| core T3 must special-case ZCode | **YES** (no external contract exists) |

## Recommendation

**NO-GO. Do not build `ZCodeDriver` against the bundled `zcode-cli`.** The transport is structured (MCP/stdio) but the access boundary is internal, token-gated, and ZCode reaps anything that isn't a legitimate launcher-spawned helper. Any bridge is either a credential-extraction exercise or a binary-patching exercise — both are on the package's NO-GO list and both break on upgrade.

If ZCode later ships `zcode-cli` as a **documented external binary** (a real CLI with `--help`, a stable `--port`/`--stdio`, and a published "headless mode" that preserves app-plan economics), this decision can be re-opened. Until then, the path for ZCode users is to keep using ZCode Desktop directly (the package's G1 option), and the path for T3 is to treat ZCode as out-of-scope.

## What this does NOT block

- The OpenCode→Qwen path (Task B) is unaffected; OpenCode has a documented stdio protocol.
- The minimal handoff design (Task D) is unaffected.
- A future *native* Qwen Code driver (if Qwen Code ships a documented harness protocol) is unaffected.

## Raw evidence captured

- `evidence/zcode-cli-observation-20260807-091308.txt` — `ps` + `lsof` for PID 1030 (network, unix sockets, open files).
- `evidence/zcode-cli-static-scan-20260807-091354.txt` — `~/.zcode` layout, app.asar presence.
- `evidence/zcode-cli-asar-surface-20260807-091440.txt` — asar top-level layout (`/out`, `/node_modules`, `/package.json`).
- Protocol-surface string counts and reap-logic excerpts: captured in this document (E4/E5); full `out/host/index.js` available on-disk from `app.asar` for re-extraction if needed.
