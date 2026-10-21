# CI Kit

Run your CI on your laptop, before you push.

CI Kit gives a repository a local gate that mirrors what the GitHub Actions
workflows do: the same installs, the same linters, the same type checks, the
same tests. It also runs the workflows themselves locally through
[act](https://github.com/nektos/act), so the YAML can be checked without
waiting for a runner.

It works with any language — the gates are driven by what the repository
contains — and it deliberately does not take over your pipeline. The
workflows stay the source of truth; the kit makes them cheap to try.

```
make            # list the targets
make ci         # the full local gate
make ci-fast    # lint and type checks only
make doctor     # is my toolchain the same as the one CI pins?
make act W=ci.yml J=test
```

## Why

CI feedback is slow, and it is slow at the worst moment: after you have
already pushed. A gate that runs in ninety seconds on your machine turns a
five-minute round trip into a coffee break, and it catches the class of
failure that CI is worst at — the one that only happens on a fresh clone.

The hard part is not running the commands. It is keeping the local run and
the CI run from drifting apart. That is what this kit is for: the setup
steps live in the repository, in `scripts/ci/`, and both the Makefile and the
workflow call them.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/omeiza-workspace/ci-kit/main/bin/install.sh | sh
```

That puts the kit in `~/.local/share/ci-kit` and links `ci` into
`~/.local/bin`. From a clone:

```sh
git clone https://github.com/omeiza-workspace/ci-kit.git ~/.local/share/ci-kit
ln -s ~/.local/share/ci-kit/bin/ci ~/.local/bin/ci
```

Homebrew:

```sh
brew tap omeiza-workspace/tap && brew install ci-kit
```

## Add it to a repository

```sh
cd your-repo
ci init
```

That creates:

```
Makefile              # the entry points
.ci/ci.mk             # finds the kit, includes its targets
.ci/ci.json           # optional configuration
.actrc                # act's configuration for this repository
.env.act.example      # the environment act reads, kept apart from .env
```

Then wire the gate into your push:

```sh
make hooks-install
```

For a repository that must not depend on anything outside itself:

```sh
ci init --vendor      # copies the kit into .ci/kit
```

Commit `.ci/kit` and the repository becomes self-contained.

## What the gate runs

The kit detects the stacks in the repository and runs the gates that stack
has. It reads `package.json`, `composer.json` and `go.mod` rather than
guessing, so a project that has no lint step does not get one invented for
it.

| Stack | Gates |
|---|---|
| Node (Vite, Vue, Quasar) | install, type check, lint, unit tests, build |
| Nuxt | install, `nuxt typecheck`, tests, build |
| PHP (Laravel, packages) | install, static analysis, code style, tests |
| Go (single module or workspace) | `go vet`, `go test`, `go build` |

Nothing is guessed. If a stack has no test runner, the tests are skipped
rather than faked.

## Running the workflows themselves

```sh
make act-list                      # what can be run
make act W=backend-tests.yml J=lint
```

act runs the workflow in a container that resembles a GitHub runner. The kit
sets the sensible defaults: the working tree is bind-mounted so the run is
fast and sees your uncommitted changes, the image is not pulled when it is
already local, and the environment comes from `.env.act` rather than the
project's own `.env`.

Use act for the things a laptop cannot do the same way: secret scanning
steps, artifact uploads, service containers, and the workflow wiring itself.
Use `make ci` for the fast loop.

## Configuration

`.ci/ci.json` is optional. Every field has a sensible default.

```json
{
  "stack": ["node"],
  "services": ["mysql", "redis"],
  "composeFile": "docker-compose.yml",
  "act": {
    "image": "catthehacker/ubuntu:act-latest",
    "envFile": ".env.act",
    "secretFile": ".secrets"
  }
}
```

## Keeping the local run and CI honest

The failure mode of every tool like this is drift: the local gate passes and
CI fails, so people stop trusting the gate. Three things prevent it here.

**The setup lives in the repository.** `scripts/ci/setup-laravel.sh` and
friends are called by both the Makefile and the workflow. There is one copy
of the setup, so it cannot disagree with itself.

**`ci doctor` compares the toolchain with the pins.** If the workflows pin
PHP 8.3 and the machine has PHP 8.4, the doctor says so, instead of leaving
you to guess why the results differ.

**The version pin is a file.** `.nvmrc` or the `engines` field in
`package.json` tells the doctor which Node the project expects, and gives
you the exact `nvm use` command to run.

## Services

Databases and caches come from the compose file the repository already has:

```sh
make services-up           # every service in the compose file
make services-up SERVICES="mysql redis"
make services-status
```

`ci init` adds `.act-artifacts/`, `.env.act` and `.secrets` to `.gitignore`.

## Requirements

- bash 3.2 or later
- node (the kit reads `package.json` and `composer.json` with it)
- docker, for the services and for act
- the toolchain of the stack you are working in
- [act](https://github.com/nektos/act), for the workflow runs

## Layout

```
bin/ci            the command line interface
bin/install.sh    the installer
lib/              the gates, one file per concern
make/ci.mk        the make targets
templates/        what `ci init` writes into a repository
tests/            the test suite
```

## Development

```sh
tests/run.sh              # the test suite
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable   # lint
```

The kit lints itself with ShellCheck in CI, on Ubuntu and macOS.

## Licence

MIT. See [LICENSE](LICENSE).
