#!/usr/bin/env bash
# Stack detection: what kind of project is this repository?

# ci_detect_stacks <root> — print detected stacks, one per line: node nuxt php go
ci_detect_stacks() {
  local root="${1:-$PWD}"
  if ls "$root"/nuxt.config.* >/dev/null 2>&1; then
    printf 'nuxt\n'
  elif [ -f "$root/package.json" ]; then
    printf 'node\n'
  fi
  if [ -f "$root/composer.json" ]; then
    printf 'php\n'
  fi
  if [ -f "$root/go.mod" ] || [ -f "$root/go.work" ]; then
    printf 'go\n'
  fi
}

# ci_is_laravel_app <root> — true when the repo is an application, not a package.
ci_is_laravel_app() {
  local root="${1:-$PWD}"
  [ -f "$root/artisan" ]
}

# ci_workflow_dir <root>
ci_workflow_dir() {
  printf '%s/.github/workflows\n' "${1:-$PWD}"
}

# ci_list_workflows <root> — print workflow file names, one per line.
ci_list_workflows() {
  local dir; dir="$(ci_workflow_dir "${1:-$PWD}")"
  [ -d "$dir" ] || return 0
  local f
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.yml|*.yaml) basename "$f" ;;
    esac
  done
}

# ci_workflow_jobs <root> <file> — print the job ids of a workflow.
ci_workflow_jobs() {
  local wf="$1"
  [ -f "$wf" ] || return 0
  # Job ids sit at two-space indentation under "jobs:".
  awk '/^jobs:/{in_jobs=1; next} in_jobs && /^[^ ]/{in_jobs=0} in_jobs && /^  [A-Za-z0-9_-]+:/{gsub(/[ :]/,"",$0); print $0}' "$wf"
}
