#!/usr/bin/env bash
# Mock services: the stand-ins for the outside world a test needs.
#
# The kit does not know what a mock is. It knows how to start a command, how
# to wait for an endpoint to answer, and how to say clearly which one is
# missing. The mock engine itself belongs to the repository that has it.
#
# Configuration lives in .ci/ci.json:
#
#   "mocks": {
#     "command": "npx api-mock-services start paystack interswitch",
#     "cwd": "../api-mock-services",
#     "endpoints": {
#       "paystack": "http://127.0.0.1:4005",
#       "interswitch": "http://127.0.0.1:4006"
#     }
#   }

# ci_mocks_config <key> — read a value from the mocks section.
ci_mocks_config() {
  ci_config "config.mocks && config.mocks['$1']" ""
}

# ci_mocks_endpoints — the name and url of every configured mock, one per line.
ci_mocks_endpoints() {
  local raw
  raw="$(ci_config 'config.mocks && config.mocks.endpoints ? Object.entries(config.mocks.endpoints).map(([k,v]) => k + "=" + v).join("\n") : ""' "")"
  [ -n "$raw" ] && printf '%s\n' "$raw"
}

# ci_mocks_split <url> — set MOCK_HOST and MOCK_PORT from a URL.
ci_mocks_split() {
  local url="$1" stripped
  stripped="${url#*://}"
  stripped="${stripped%%/*}"
  stripped="${stripped%%\?*}"
  if [ "$stripped" != "${stripped%:*}" ]; then
    MOCK_HOST="${stripped%:*}"
    MOCK_PORT="${stripped##*:}"
  else
    MOCK_HOST="$stripped"
    MOCK_PORT=""
  fi
  export MOCK_HOST MOCK_PORT
}

# ci_mocks_status — report every mock, and whether it is answering.
ci_mocks_status() {
  local name url rc=0 any=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    any=1
    name="${line%%=*}"
    url="${line#*=}"
    ci_mocks_split "$url"
    if [ -n "$MOCK_PORT" ] && ci_port_is_open "$MOCK_HOST" "$MOCK_PORT"; then
      ci_ok "$name is up ($url)"
    else
      ci_err "$name is not answering ($url)"
      rc=1
    fi
  done < <(ci_mocks_endpoints)
  [ "$any" = "0" ] && ci_dim "no mocks are configured for this repository"
  return $rc
}

# ci_mocks_assert — the gate's preflight.
# A gate that silently starts services hides the reason a test failed, so the
# kit never starts anything here. It says what is missing and how to start it.
#
# The check is opt-in: a repository sets "assert": true in its mocks section
# when its gate genuinely needs them. A repository whose tests start the mocks
# themselves, in the test process, has nothing to check.
ci_mocks_assert() {
  local assert
  assert="$(ci_config 'config.mocks && config.mocks.assert' "false")"
  [ "$assert" = "true" ] || return 0

  local missing=0 any=0
  local line name url
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    any=1
    name="${line%%=*}"
    url="${line#*=}"
    ci_mocks_split "$url"
    if [ -z "$MOCK_PORT" ] || ! ci_port_is_open "$MOCK_HOST" "$MOCK_PORT"; then
      missing=$((missing + 1))
      ci_err "the $name mock is not answering on $url"
    fi
  done < <(ci_mocks_endpoints)
  [ "$any" = "0" ] && return 0
  if [ "$missing" -gt 0 ]; then
    ci_err "$missing mock(s) are not running. Start them with 'make mocks-up' and run the gate again."
    return 1
  fi
  ci_ok "the mocks are up"
  return 0
}

# ci_mocks_up — start the mock engine, and wait for it.
ci_mocks_up() {
  local command cwd root
  command="$(ci_mocks_config command)"
  [ -n "$command" ] || ci_die "no mocks are configured for this repository"
  cwd="$(ci_mocks_config cwd)"
  root="${CI_ROOT:-$PWD}"
  if [ -n "$cwd" ]; then
    case "$cwd" in
      /*) ;;
      *) cwd="$root/$cwd" ;;
    esac
  else
    cwd="$root"
  fi

  ci_log "starting the mocks: $command"
  ( cd "$cwd" && nohup sh -c "$command" > "$root/.mocks.log" 2>&1 & echo $! > "$root/.mocks.pid" )

  local waited=0
  while [ "$waited" -lt 30 ]; do
    if ci_mocks_status >/dev/null 2>&1; then
      ci_mocks_status
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  ci_err "the mocks did not come up within 30s. The log is in $root/.mocks.log"
  tail -20 "$root/.mocks.log" 2>/dev/null
  return 1
}

# ci_mocks_down — stop the mock engine.
ci_mocks_down() {
  local root="${CI_ROOT:-$PWD}"
  local pid_file="$root/.mocks.pid"
  if [ ! -f "$pid_file" ]; then
    ci_dim "no mock process was started by this repository"
    return 0
  fi
  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    ci_ok "stopped the mock process ($pid)"
  fi
  rm -f "$pid_file"
}
