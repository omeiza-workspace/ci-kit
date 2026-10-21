#!/usr/bin/env bash
# Locating the kit.
#
# The kit has to work in three situations:
#   1. run from a clone      — the kit knows where it is
#   2. run from an install   — $CI_KIT, ~/.local/share/ci-kit, /usr/local/share/ci-kit
#   3. vendored in a repo    — .ci/kit, next to the shim that includes it

# ci_kit_root — the directory this kit lives in.
ci_kit_root() {
  if [ -n "${CI_KIT_ROOT:-}" ]; then
    printf '%s\n' "$CI_KIT_ROOT"
    return 0
  fi
  (cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
}

# ci_kit_locate — find an installed kit from anywhere.
ci_kit_locate() {
  local c
  for c in \
    "${CI_KIT:-}" \
    "${CI_KIT_HOME:-}" \
    "$HOME/.local/share/ci-kit" \
    "$HOME/ci-kit" \
    "/usr/local/share/ci-kit" \
    "/opt/homebrew/share/ci-kit"; do
    if [ -n "$c" ] && [ -f "$c/make/ci.mk" ]; then
      printf '%s\n' "$c"
      return 0
    fi
  done
  return 1
}

# ci_kit_version — the version of this kit.
ci_kit_version() {
  local root; root="$(ci_kit_root)"
  if [ -f "$root/VERSION" ]; then
    tr -d '[:space:]' < "$root/VERSION"
    return 0
  fi
  printf '0.0.0-dev\n'
}
