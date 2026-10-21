# Architecture

Why the kit is shaped the way it is. The short version is in the README;
this is the reasoning behind the decisions that are not obvious.

## The shape

```
bin/ci          the command line
lib/            the gates, one file per concern
make/ci.mk      the make targets a repository includes
templates/      what `ci init` writes into a repository
tests/          the test suite
docker/         the optional images
docs/           the documentation site
```

Three rules govern the boundaries.

**The kit never needs to know about a repository.** Everything it does is
derived from what is in the repository — `package.json`, `composer.json`,
`go.mod`, `.github/workflows` — or configured by the repository in
`.ci/ci.json`. There is no list of supported projects, no registry, and
nothing to update when a new project appears.

**A repository never needs to change the kit.** The extension points are
files in the repository, not hooks in the kit:

| The repository ships | The kit does |
|---|---|
| `scripts/ci/gate.sh` | runs it as the whole gate |
| `scripts/ci/gate-extra.sh` | runs it after the automatic gates |
| `scripts/ci/setup-*.sh` | nothing — the repository calls it |
| `.ci/ci.json` | reads the stack, services, mocks and the act image |

**There is one copy of the setup.** The failure mode of a tool like this is
drift: the local gate passes, CI fails, and people stop trusting the gate.
The only way to prevent it is to make the setup a single file that both the
Makefile and the workflow call. That is why the kit ships no setup steps of
its own for any particular stack — it ships the *mechanism* for sharing
them.

## The gates

The gates are derived, not configured. A stack runs the gates it declares:

- **Node** — the type check, the lint, the tests and the build come from the
  scripts in `package.json`. A project with no lint step does not get one
  invented for it, and a project that wants a different check overrides it
  with its own `gate.sh`.
- **PHP** — the same, from `composer.json` where the scripts exist and from
  `vendor/bin` where they do not.
- **Go** — `go vet`, `go test` and `go build`, across every module in a
  `go.work` when there is one.
- **Nuxt** — `nuxt typecheck`, the tests, and the build.

The alternative — a configuration file listing the commands to run — is more
flexible and much more work. It moves knowledge that the repository already
has into a file that can disagree with it. The kit takes the knowledge from
where it already is, and offers `gate.sh` for the cases where the repository
knows something the kit does not.

## Why bash

Because it is everywhere. A developer tool that runs on a laptop, in a
pre-push hook, in a container and in CI should not need a runtime that has
to be installed, version-matched or compiled for the platform. Bash 3.2 is
the floor, because that is what macOS ships and it is the version most
likely to be present when something goes wrong.

The kit reads `package.json` and `composer.json` with node, and it needs
node for the tools it drives. That is a deliberate dependency, and it is
stated in the README rather than implied.

The cost of bash is real: it has no types, its arrays are awkward, and every
shell needs a `set -euo pipefail` and a set of careful habits. The kit pays
that cost once, so that a repository's `Makefile` can be three lines long.

## Why the kit does not start services during a gate

A gate that quietly starts a database, a cache or a mock makes a failure
ambiguous. When the tests fail, the developer has to work out whether the
code is broken, or the service did not come up, or the service came up in the
wrong state. The reason for the failure is the thing the gate exists to
tell you, and a side effect throws it away.

So the kit separates the two jobs:

- `make services-up` and `make mocks-up` start things, explicitly.
- The gate *checks* that the things it needs are up, and names the one that
  is not.

A repository can opt into the check (`"mocks": { "assert": true }`), because
some gates genuinely need a service and some do not. The default is off.

## Why act is wrapped rather than replaced

act is excellent, and the kit does not try to be it. act runs a workflow in
a container; the kit runs the *steps* of a workflow natively, where it can,
because that is faster and it is the environment the developer is actually
working in.

The wrapper exists for four reasons, each of which cost somebody an
afternoon before it was handled:

1. **The daemon may not be at `/var/run/docker.sock`.** OrbStack, Colima and
   Rancher Desktop all use their own. The kit asks the docker CLI where its
   context points and tells act.
2. **The working tree should be bind-mounted.** Copying it into the
   container is slower and hides uncommitted changes, which is exactly what
   you want to test.
3. **The image should not be pulled every time.** `--pull=false` reuses a
   local image.
4. **The environment should not be the project's `.env`.** A Laravel `.env`
   is the application's, and act reads the file at the repository root by
   default. The kit uses `.env.act` and keeps them apart.

## What it costs

| | |
|---|---|
| to install | one shell script, or one brew tap |
| to run | bash, node, and the stack's own toolchain |
| at rest | nothing — the kit is not running |
| while running | one gate process, and the containers you asked for |

No daemon, no file watcher, no polling, nothing left running when it
finishes. The pre-push hook runs when you push, and only then.

## Portability

The kit runs on macOS, Linux and WSL2. The differences between the platforms
are handled rather than assumed:

- `sed -i` takes a suffix argument on BSD and not on GNU.
- `sort -V` is used for version comparison, with a fallback for the systems
  that lack it.
- The port check uses bash's `/dev/tcp`, so netcat is not required.
- The container architecture is the daemon's default, so Apple Silicon and
  arm64 servers both work.
- `/dev/null` redirections are never left behind by a function that runs in
  the caller's shell — an `exec 2>/dev/null` in a helper silenced every
  later error message during development, which is the kind of bug this
  paragraph exists to prevent.

The CI runs the test suite and ShellCheck on Ubuntu and macOS, and builds
both container images, so a portability regression fails the build rather
than being discovered on somebody's machine.
