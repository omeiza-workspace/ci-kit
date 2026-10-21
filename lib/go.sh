#!/usr/bin/env bash
# Go gates. Sourced by bin/ci.

# ci_go_modules <root> — print the module directories of a go workspace, or "." for a single module.
ci_go_modules() {
  local root="${1:-$PWD}"
  if [ -f "$root/go.work" ]; then
    sed -n '/^use (/,/^)/p' "$root/go.work" \
      | grep -oE '^\s+\S+' | tr -d ' ' | while read -r m; do
          [ "$m" = "." ] && continue
          printf '%s\n' "$m"
        done
    return 0
  fi
  printf '.\n'
}

# ci_go_gates <root> [fast] — vet, test, build across the workspace.
ci_go_gates() {
  local root="${1:-$PWD}" fast="${2:-0}" rc=0 mod failed=""

  ci_section "Go gates"
  ci_require go "Install Go."

  for mod in $(ci_go_modules "$root"); do
    [ -d "$root/$mod" ] || continue
    ci_step "go vet ./...  ($mod)"
    (cd "$root/$mod" && go vet ./...) || { rc=1; failed="$failed $mod"; continue; }

    if [ "$fast" = "1" ]; then
      continue
    fi

    ci_step "go test ./...  ($mod)"
    (cd "$root/$mod" && go test ./...) || { rc=1; failed="$failed $mod"; }
  done

  if [ "$fast" != "1" ]; then
    ci_step "go build ./...  (.)"
    (cd "$root" && go build ./...) || rc=1
  fi

  if [ -n "$failed" ]; then
    ci_err "failed modules:$failed"
  fi
  return $rc
}
