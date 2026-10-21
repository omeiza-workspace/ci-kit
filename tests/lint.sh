#!/usr/bin/env bash
#
# Lint the kit with ShellCheck.
#
# The sources are followed with -x, so the kit's own libraries are checked
# with the files that use them. ShellCheck is not a dependency of the kit:
# the run uses whichever version is on the machine, or the container image
# when there is none.
#
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$KIT_ROOT"

FILES=(bin/ci bin/install.sh lib/*.sh tests/*.sh tests/*.test.sh)

if command -v shellcheck >/dev/null 2>&1; then
  exec shellcheck -x "${FILES[@]}"
fi

echo "shellcheck is not installed; using the container image instead."
exec docker run --rm -v "$KIT_ROOT:/mnt" -w /mnt koalaman/shellcheck:stable -x "${FILES[@]}"
