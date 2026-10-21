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
- `ci services` — starts and stops the services in the repository's compose
  file.
- `ci hooks install` — wires `make ci` into the pre-push hook.
- `ci init [--vendor]` — scaffolds the kit into a repository, optionally
  vendoring it so the repository needs nothing outside itself.
- `.ci/ci.json` — optional per-repository configuration for the stack, the
  services and the act image.
- The `scripts/ci/gate.sh` contract: a repository that ships this script
  controls its own gate, and the same script runs on a laptop and on a
  runner.

### Notes

- The kit never edits a workflow. The workflow stays the source of truth; the
  kit makes it cheap to try.
