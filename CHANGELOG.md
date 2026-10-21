# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — Unreleased

### Added

- `ci doctor` — compares the local toolchain with the versions the workflows
  pin, and prints the fix when they differ.
- `ci gate` — runs the local gate for every stack in the repository: Node,
  Nuxt, PHP and Go. The gates are derived from `package.json`,
  `composer.json` and `go.mod`, so nothing is invented for a project that does
  not have it.
- `ci act` — runs a workflow locally through act, with the working tree
  bind-mounted, the image reused when it is local, and the environment read
  from `.env.act` rather than the project's own `.env`.
- `ci mocks` — starts, stops and checks the stand-ins for the outside world a
  test needs. The kit knows how to start a command and how to tell whether an
  endpoint is answering; what a mock is belongs to the repository that has
  it. A gate can opt in to checking them with `"assert": true`.
- `ci services` — starts and stops the services in the repository's compose
  file.
- `ci hooks install` — wires `make ci` into the pre-push hook.
- `ci init [--vendor]` — scaffolds the kit into a repository, optionally
  vendoring it so the repository needs nothing outside itself.
- `.ci/ci.json` — optional per-repository configuration for the stack, the
  services, the mocks and the act image.
- The `scripts/ci/gate.sh` contract: a repository that ships this script
  controls its own gate, and the same script runs on a laptop and on a
  runner.
- Container images: `docker/Dockerfile` carries the kit, and
  `docker/Dockerfile.toolbox` adds PHP 8.3, Composer 2, Node 22 and Go 1.23.

### Fixed

- act is pointed at the daemon the docker CLI talks to, so it works where
  the socket is not `/var/run/docker.sock` — OrbStack, Colima, Rancher
  Desktop.
- The port check opens its connection in a subshell. Closing the descriptor
  in the calling shell left a permanent `exec 2>/dev/null` behind, which
  silenced every later error message.
- BSD and GNU `sed` are both handled, so a repository's setup script works on
  macOS as well as on Linux.
- The port check uses `/dev/tcp`, so netcat is not required.
- The release archive is built with `git archive`, not GNU tar.

### Notes

- The kit never edits a workflow. The workflow stays the source of truth; the
  kit makes it cheap to try.
- The kit does not start services during a gate. A gate that quietly starts
  things hides the reason a test failed.
