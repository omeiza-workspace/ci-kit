#!/usr/bin/env bash
# Local service (database, cache, mail) management via docker compose.
# Sourced by bin/ci.

# ci_compose_cmd — echo the compose command available on this machine.
ci_compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    printf 'docker compose'
  elif ci_have docker-compose; then
    printf 'docker-compose'
  else
    return 1
  fi
}

# ci_compose_file <repo root> — echo the compose file to use, empty if none.
ci_compose_file() {
  local root="${1:-$PWD}" f configured
  configured="$(ci_config 'config.composeFile' "")"
  if [ -n "$configured" ]; then
    case "$configured" in
      /*) [ -f "$configured" ] && { printf '%s\n' "$configured"; return 0; } ;;
      *)  [ -f "$root/$configured" ] && { printf '%s\n' "$root/$configured"; return 0; } ;;
    esac
  fi
  for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml docker-compose.local.yml; do
    [ -f "$root/$f" ] && { printf '%s\n' "$root/$f"; return 0; }
  done
  return 1
}

# ci_services_up [service...] — start services (default: all in the compose file).
ci_services_up() {
  local root="${CI_ROOT:-$PWD}" file cmd
  cmd="$(ci_compose_cmd)" || ci_die "docker compose is not available"
  file="$(ci_compose_file "$root")" || ci_die "no compose file found in $root"
  ci_log "starting services from $(basename "$file")"
  # The command is a string because it may be two words, "docker compose".
  # shellcheck disable=SC2086
  if [ "$#" -gt 0 ]; then
    ci_run $cmd -f "$file" up -d "$@"
  else
    ci_run $cmd -f "$file" up -d
  fi
}

# ci_services_down [service...]
ci_services_down() {
  local root="${CI_ROOT:-$PWD}" file cmd
  cmd="$(ci_compose_cmd)" || ci_die "docker compose is not available"
  file="$(ci_compose_file "$root")" || ci_die "no compose file found in $root"
  # shellcheck disable=SC2086
  if [ "$#" -gt 0 ]; then
    ci_run $cmd -f "$file" down "$@"
  else
    ci_run $cmd -f "$file" down
  fi
}

# ci_services_status
ci_services_status() {
  local root="${CI_ROOT:-$PWD}" file cmd
  cmd="$(ci_compose_cmd)" || ci_die "docker compose is not available"
  file="$(ci_compose_file "$root")" || ci_die "no compose file found in $root"
  # shellcheck disable=SC2086
  ci_run $cmd -f "$file" ps
}

# ci_services_wait <host> <port> [timeout] — block until a port answers.
ci_services_wait() {
  local host="${1:-127.0.0.1}" port="$2" timeout="${3:-90}"
  ci_step "waiting for $host:$port"
  if ci_wait_port "$host" "$port" "$timeout"; then
    ci_ok "$host:$port is up"
  else
    ci_die "$host:$port did not open within ${timeout}s"
  fi
}
