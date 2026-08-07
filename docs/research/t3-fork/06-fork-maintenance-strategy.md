# Fork Maintenance Strategy

## Remotes

```bash
git remote add upstream https://github.com/pingdotgg/t3code.git
git fetch upstream
```

Keep custom features isolated from fork `main`:

```text
upstream/main
  -> fork/main
       -> feature/qwen-driver
       -> research/zcode-cli
       -> feature/zcode-driver
       -> feature/handoff
```

## Patch-surface budget

- GREEN: new provider-local files/tests/docs.
- YELLOW: provider registry/settings/picker.
- RED: orchestration/contracts/client-runtime/checkpoint core.

Track how many RED/YELLOW files each custom feature touches.

## Rebase discipline

Keep one concern per feature branch. Do not mix provider work, branding, and workflow changes.

For custom releases record exact upstream base SHA and tag the fork, e.g.:

```text
fork-20260807.1
```

## Upstream contributions

Generic SPI/reliability fixes may be upstreamable. Experimental ZCode internal integration and personal workflow features should be assumed private. Upstream `CONTRIBUTING.md` currently warns that large unsolicited features are unlikely to be accepted.
