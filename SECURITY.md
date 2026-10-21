# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 0.1.x | yes |

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Report it privately through GitHub's
[private vulnerability reporting](https://github.com/omeiza-workspace/ci-kit/security/advisories/new),
or by email to the maintainer. Include:

- what the problem is, and what an attacker could do with it
- the version of the kit, and of the toolchain it runs on
- the steps to reproduce it

You will get an acknowledgement within a few days, and a fix or an
explanation of why the report is not a vulnerability.

## What the kit does with your code

The kit is a local program. It reads your repository, runs the commands in
your Makefile and in `scripts/ci/`, and starts the containers your compose
file describes. It sends nothing anywhere.

Two things are worth knowing:

- **`act` runs your workflow.** A workflow is arbitrary code, and `act`
  runs it in a container on your machine, with your working tree mounted.
  That is the point of it, and it is also a reason to read a workflow
  before running it.
- **The mock services and the services in your compose file are local.** The
  kit starts them on your machine, on the ports your configuration names.
  They are not exposed to the network by the kit, and they are not
  authenticated. Do not point them at anything that matters.

## Secrets

The kit reads a secrets file for `act`, `.secrets` by default, and it is
added to `.gitignore` by `ci init`. The kit never writes a secret anywhere
and never sends one off the machine.

`ci doctor` prints tool versions. It does not print environment values.
