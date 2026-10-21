#!/usr/bin/env bash
# Shared helpers for the CI kit. Sourced, never executed.

if [ -t 1 ] && [ -z "${CI_NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[1;31m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
  C_BLUE=$'\033[1;34m'; C_CYAN=$'\033[1;36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_CYAN=''
fi

ci_log()   { printf '%s[ci]%s %s\n' "$C_CYAN" "$C_RESET" "$*"; }
ci_ok()    { printf '%s[ci]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
ci_warn()  { printf '%s[ci]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
ci_err()   { printf '%s[ci]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
ci_dim()   { printf '%s[ci]%s %s%s\n' "$C_DIM" "$C_RESET" "$*" "$C_RESET"; }
ci_die()   { ci_err "$*"; exit 1; }

ci_section() {
  printf '\n%s%s==> %s%s\n' "$C_BOLD" "$C_BLUE" "$*" "$C_RESET"
}

ci_step() {
  printf '%s  ->%s %s\n' "$C_BLUE" "$C_RESET" "$*"
}

# ci_have <command> — true when the command exists on PATH.
ci_have() { command -v "$1" >/dev/null 2>&1; }

# ci_require <command> [hint]
ci_require() {
  ci_have "$1" || ci_die "'$1' is required but not on PATH.${2:+ $2}"
}

# ci_run <command...> — echo the command, then run it, preserving its exit code.
ci_run() {
  ci_dim "\$ $*"
  "$@"
}

# ci_repo_root — the nearest ancestor holding a VCS or package marker.
ci_repo_root() {
  local dir="${1:-$PWD}"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ] || [ -f "$dir/package.json" ] || [ -f "$dir/composer.json" ] || [ -f "$dir/go.mod" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  printf '%s\n' "$PWD"
}

# ci_json_scripts <package.json path> — print the script names, one per line.
ci_json_scripts() {
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    for (const k of Object.keys(p.scripts || {})) console.log(k);
  ' "$1" 2>/dev/null
}

# ci_json_script <package.json path> <script name> — print the command, empty if absent.
ci_json_script() {
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    process.stdout.write((p.scripts || {})[process.argv[2]] || "");
  ' "$1" "$2" 2>/dev/null
}

# ci_json_script_names <package.json path> — print script names matching a regex.
ci_json_script_names() {
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const re = new RegExp(process.argv[2]);
    for (const k of Object.keys(p.scripts || {})) if (re.test(k)) console.log(k);
  ' "$1" "$2" 2>/dev/null
}

# ci_composer_scripts <composer.json path> — print script names, one per line.
ci_composer_scripts() {
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    for (const k of Object.keys(p.scripts || {})) console.log(k);
  ' "$1" 2>/dev/null
}

# ci_composer_script <composer.json path> <name>
ci_composer_script() {
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    process.stdout.write((p.scripts || {})[process.argv[2]] || "");
  ' "$1" "$2" 2>/dev/null
}

# ci_sed_inplace <sed expression> <file> — edit a file in place.
# GNU sed and BSD sed disagree about the argument to -i, so the difference is
# detected rather than assumed.
ci_sed_inplace() {
  local expression="$1" file="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i "$expression" "$file"
  else
    sed -i '' "$expression" "$file"
  fi
}

# ci_port_is_open <host> <port> — true when something is listening.
# bash's /dev/tcp is used first: netcat is not installed everywhere, and this
# works on every bash build since 2.0.
#
# The connection is opened in a subshell, so the descriptor is closed when it
# ends. Closing it in this shell instead would leave a permanent redirection
# behind — `exec 2>/dev/null` silences stderr for the rest of the run.
ci_port_is_open() {
  local host="$1" port="$2"
  if (exec 3<>"/dev/tcp/${host}/${port}") 2>/dev/null; then
    return 0
  fi
  if command -v nc >/dev/null 2>&1; then
    nc -z "$host" "$port" >/dev/null 2>&1
    return $?
  fi
  return 1
}

# ci_wait_port <host> <port> <timeout seconds>
ci_wait_port() {
  local host="$1" port="$2" timeout="${3:-60}" waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if ci_port_is_open "$host" "$port"; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}
