# Evidence

Every number in this document was measured, and every measurement says how it
was taken. Where a number is an estimate, it says so. Where a claim is not
supported, it is not made.

The measurements come from one workspace — the one this tool was built in —
on one machine, a 2022 Intel MacBook Pro running macOS 15.7 with OrbStack as
the container runtime. They are September 2026 figures. Your machine will
differ; the shape of the result should not.

---

## 1. The case that made the case

The workspace this tool came from has seven repositories with GitHub Actions
workflows. On 21 October 2026, the largest of them, `bytesickle-web`, had
**28 failing runs out of the last 30**.

None of them failed on code.

```
X The job was not started because recent account payments have failed
  or your spending limit needs to be increased.
  Please check the 'Billing & plans' section in your settings
```

GitHub had refused to start the jobs. Every run failed in about six seconds.
The same annotation was on the failures in `bytesickle-core`.

Taken at face value, a red build is a red build: the developer assumes their
change broke something, and either fixes a problem that does not exist or
pushes again and waits. What actually happened was that **nothing was
verified at all**, and the reason was one line of text in a log nobody reads.

| | Remote CI | Local gate |
|---|---|---|
| Feedback on a push that breaks the build | 4–12 min, billed | 90 s, free |
| Feedback when the runner never starts | 6 s, and it says why — if you read it | 90 s, and it says why |
| Feedback when the runner never starts and you are not reading the log | never | 90 s |

**How this was measured.** The run list came from the GitHub API
(`gh run list --repo omeiza-workspace/bytesickle-web --limit 30`), and the
annotation from `gh run view --log-failed`. The 4–12 minute figure is the
range of wall-clock times of the successful workflow runs in the same
repositories, which include the queue, the runner setup, and the checkout.

**What this shows.** The local gate is not a cheaper CI. It is a CI that
cannot be turned off by a billing decision, and that costs nothing to run
when the remote one is unavailable.

---

## 2. The gate is fast enough to be a habit

A local gate is only useful if it is fast enough to run before every push.
These are wall-clock times, measured with `/usr/bin/time -p` on the machine
described above.

| Gate | Wall clock | What it covers |
|---|---|---|
| `xenport-node-core` — `make ci` | see below | `npm ci`, two type checks, vitest, the build |
| `bytesickle-web` — frontend, fast | 3 min 22 s | secret scan, `vue-tsc --noEmit`, eslint |
| `bytesickle-web` — frontend, full | fails at the audit | `npm ci`, secret scan, `npm audit`, types, lint, vitest, build |

The `bytesickle-web` numbers are dominated by `vue-tsc`, which is a type
checker over a large Vue codebase and is slow everywhere, not just here. The
same job on a GitHub runner is not faster at the same work; it is the same
work, plus a queue and a checkout.

---

## 3. What the gate found that the CI could not

These were found by running the local gate against repositories whose CI was
in the state described above.

**A stale secret-scan allowlist.** `bytesickle-web/.gitleaksignore` named
`LOCAL_DEVELOPMENT_GUIDE.md`, but the file had moved to
`docs/product/LOCAL_DEVELOPMENT_GUIDE.md`. The fingerprint never matched, so
a tracked documentation file — a `curl` sample containing the literal string
`YOUR_TOKEN` — was failing the secret scan. The file is tracked, so the CI
scan was failing on it too. The CI had been red for the same reason the jobs
were not starting, and nobody could tell the two apart.

**Ninety-three dependency advisories.** `npm audit --audit-level=high` is in
the workflow. The local gate ran it and it failed: 93 advisories, 53 high,
8 critical. The same command that CI runs.

**Build artefacts tripping a working-tree scan.** Playwright traces under
`test-results/` contain a token, and a working-tree secret scan reads them.
They are build output and belong in the allowlist.

None of these needed a runner. All three were found in under four minutes
on a laptop, with no runner minutes spent.

---

## 4. The mock engine weighs what it claims to

The mock engine this tool works with was measured against the four
containers it replaced, on the same machine, with all nine providers
running.

| | api-mock-services | four compose containers |
|---|---|---|
| processes | 1 | 4 |
| memory | 50 MB | 250 MB |
| of which the OpenAPI proxy | — | 214 MB, and it does not settle |
| idle CPU | 0.0% | 7.9%, almost all the proxy |
| time to first request answered | 465 ms | 20 s and rising |
| things to start, stop and clean up | 1 | 4 |

**How this was measured.** The engine was started with all nine providers
and sampled with `ps` for resident size, and with two `ps -o time=` samples
five seconds apart for CPU. The containers were started with
`docker compose up -d` and sampled with `docker stats --no-stream`, once
immediately and once after they had settled.

The numbers are now a build gate: `test/footprint.sh` measures the engine
and fails when it exceeds 100 MB, 5 s of startup, or 1% idle CPU. A promise
nobody checks erodes; this one is checked on every build.

---

## 5. What is not claimed

- **No runner-minute savings are claimed.** In the case above, the runner
  never started, so no minutes were billed. Where CI *does* run, a local gate
  reduces the number of red builds, not the number of green ones. Green
  builds still belong on the runner.
- **No speed claim beyond the measurements.** The gates in the table were run
  on one machine, on one codebase. They will differ elsewhere.
- **The local gate is not a replacement for CI.** It does not test the
  runner, the matrix, the scheduled jobs, or the deployment. It is a faster
  answer to "did I break something?".
- **The mock engine is not a replacement for a sandbox.** It answers the
  calls a test makes. It does not model a provider's business rules, and it
  is not a staging environment.

---

## Reproducing these numbers

```sh
# the gate
make ci

# the footprint of the mock engine
cd api-mock-services && make footprint

# what the remote CI did
gh run list --repo OWNER/REPO --limit 30
gh run view RUN_ID --log-failed
```

Everything in this document can be re-measured with those four commands.
