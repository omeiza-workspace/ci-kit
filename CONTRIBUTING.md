# Contributing

Thanks for taking the time. This is a small project and the bar for a change
is simple: it must work on a machine that has nothing but bash, node and
docker, and it must not assume anything about the repository it runs in.

## Getting set up

```sh
git clone https://github.com/omeiza-workspace/ci-kit.git
cd ci-kit
tests/run.sh
```

## Before you open a pull request

```sh
make check
```

Both run in CI, on Ubuntu and macOS. The test suite is plain bash on
purpose: a contributor should be able to run it without installing a
framework.

## House rules

**No new dependencies.** bash, node and docker are the whole toolchain. A
language-specific tool (php, composer, go, npm) is fine to *call* — the kit
already does — but the kit itself must not require it.

**The gates are derived, not guessed.** A stack runs the gates it declares.
If a project has no lint step, the kit does not invent one. This is what
keeps the local run honest about the CI run.

**The repository owns its setup.** Anything a workflow and a laptop both need
belongs in `scripts/ci/` in that repository, not in this kit. The kit
provides the orchestration; the repository provides the steps.

**Nothing is written outside the repository without being asked.** `ci init`
writes into the repository it is run in. `ci hooks install` writes a hook and
sets `core.hooksPath` in that repository. Nothing else touches the system.

## Adding a stack

1. Add `lib/<stack>.sh` with a `ci_<stack>_gates` function that takes the
   repository root and a `fast` flag, and returns non-zero when a gate fails.
2. Add the detection to `lib/stack.sh`.
3. Add a case to the gate loop in `bin/ci`.
4. Add a fixture under `tests/` and a row to the table in the README.

The gate function must not `exit`. It must return a status, so the other
stacks still run and the report lists everything that failed.

## Releasing

1. Update `CHANGELOG.md`.
2. Bump `VERSION`.
3. Tag: `git tag -a v0.2.0 -m "v0.2.0"` and push the tag.

The release workflow publishes the archive and the install snippet.
