#!/usr/bin/env bash
#
# The CI kit test suite.
#
#   tests/run.sh            run everything
#   tests/run.sh stack      run the files whose name matches "stack"
#
# No test framework is required: the suite is plain bash, so it runs on a
# machine that has nothing but bash and node.
#
set -uo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$KIT_ROOT/tests"

PASS=0
FAIL=0

# ------------------------------------------------------------------ harness ---

ok()    { PASS=$((PASS + 1)); printf '  \033[1;32mok\033[0m   %s\n' "$1"; }
notok() { FAIL=$((FAIL + 1)); printf '  \033[1;31mFAIL\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; return 0; }

assert_true() {
  if [ -n "${CI_TEST_VERBOSE:-}" ]; then
    "$@" 2>&1 | sed 's/^/       | /'
    local status=${PIPESTATUS[0]}
  else
    "$@" >/dev/null 2>&1
    local status=$?
  fi
  if [ "$status" -eq 0 ]; then ok "$*"; else notok "$*" "the command failed ($status)"; fi
}

# assert_cmd <message> <command...>
assert_cmd() {
  local message="$1"; shift
  if [ -n "${CI_TEST_VERBOSE:-}" ]; then
    "$@" 2>&1 | sed 's/^/       | /'
    local status=${PIPESTATUS[0]}
  else
    "$@" >/dev/null 2>&1
    local status=$?
  fi
  if [ "$status" -eq 0 ]; then ok "$message"; else notok "$message" "the command failed ($status)"; fi
}

assert_false() {
  if "$@" >/dev/null 2>&1; then notok "$*" "the command unexpectedly succeeded"; else ok "not: $*"; fi
}

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  if [ "$expected" = "$actual" ]; then
    ok "$message"
  else
    notok "$message" "expected '$expected', got '$actual'"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" message="$3"
  case "$haystack" in
    *"$needle"*) ok "$message" ;;
    *) notok "$message" "'$needle' not found" ;;
  esac
}

assert_file() {
  if [ -f "$1" ]; then ok "$2"; else notok "$2" "$1 does not exist"; fi
}

assert_no_file() {
  if [ -f "$1" ]; then notok "$2" "$1 exists"; else ok "$2"; fi
}

# A temporary directory that is cleaned up when the test file finishes.
TEST_TMP=""
make_tmp() {
  TEST_TMP="$(mktemp -d)"
  trap 'rm -rf "$TEST_TMP"' EXIT
}

# -------------------------------------------------------------------- main ---

# shellcheck source=lib/paths.sh
source "$KIT_ROOT/lib/paths.sh"
# shellcheck source=lib/common.sh
source "$KIT_ROOT/lib/common.sh"
# shellcheck source=lib/config.sh
source "$KIT_ROOT/lib/config.sh"
# shellcheck source=lib/stack.sh
source "$KIT_ROOT/lib/stack.sh"

FILTER="${1:-}"
for file in "$TESTS_DIR"/*.test.sh; do
  [ -e "$file" ] || continue
  if [ -n "$FILTER" ] && [[ "$file" != *"$FILTER"* ]]; then continue; fi
  # shellcheck source=/dev/null
  source "$file"
done

for name in $(declare -F | awk '{print $3}' | grep '^test_'); do
  printf '\n\033[1;36m%s\033[0m\n' "${name#test_}"
  "$name"
done

if [ "$FAIL" -eq 0 ]; then
  printf '\n\033[1;32m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
else
  printf '\n\033[1;31m%d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
fi

[ "$FAIL" -eq 0 ]
