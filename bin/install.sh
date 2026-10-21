#!/usr/bin/env bash
#
# Install the CI kit.
#
#   curl -fsSL https://raw.githubusercontent.com/omeiza-workspace/ci-kit/main/bin/install.sh | sh
#   curl -fsSL ... | sh -s -- --version v1.0.0
#
# The kit lands in ~/.local/share/ci-kit and a symlink to bin/ci is placed in
# ~/.local/bin, which is on the PATH for most shells.
#
set -euo pipefail

VERSION="main"
PREFIX="${CI_KIT_PREFIX:-$HOME/.local/share/ci-kit}"
BIN_DIR="${CI_KIT_BIN_DIR:-$HOME/.local/bin}"
REPO="https://github.com/omeiza-workspace/ci-kit.git"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --prefix)  PREFIX="$2"; shift 2 ;;
    --bin-dir) BIN_DIR="$2"; shift 2 ;;
    --repo)    REPO="$2"; shift 2 ;;
    --help|-h)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git is required"

if [ -d "$PREFIX/.git" ]; then
  say "updating $PREFIX"
  git -C "$PREFIX" pull --ff-only
else
  say "installing the kit into $PREFIX"
  mkdir -p "$(dirname "$PREFIX")"
  if [ "$VERSION" = "main" ]; then
    git clone --depth 1 "$REPO" "$PREFIX"
  else
    git clone --depth 1 --branch "$VERSION" "$REPO" "$PREFIX"
  fi
fi

mkdir -p "$BIN_DIR"
ln -sf "$PREFIX/bin/ci" "$BIN_DIR/ci"
say "linked $BIN_DIR/ci"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "note: $BIN_DIR is not on your PATH — add it to your shell profile" ;;
esac

say "done. Run 'ci --version', then 'cd <your repo> && ci init'."
