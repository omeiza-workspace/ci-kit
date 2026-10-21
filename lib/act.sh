#!/usr/bin/env bash
# act wrapper. Sourced by bin/ci.
#
# act reads $HOME/.actrc and then ./.actrc, so per-repo configuration wins.
# The wrapper adds the defaults a local run wants: bind mount (fast, dirty tree),
# no image pull when the image is already local, and a project-specific env file
# so a Laravel .env is never clobbered.

CI_ACT_DEFAULT_IMAGE="${CI_ACT_DEFAULT_IMAGE:-catthehacker/ubuntu:act-latest}"

# ci_act_image — the container image act should run the workflow in.
ci_act_image() {
  local image
  image="$(ci_config 'config.act && config.act.image' "$CI_ACT_DEFAULT_IMAGE")"
  printf '%s\n' "$image"
}

# ci_act_env_file <root> — the env file act should read.
ci_act_env_file() {
  local root="${1:-$PWD}" configured
  configured="$(ci_config 'config.act && config.act.envFile' "")"
  if [ -n "$configured" ]; then
    case "$configured" in
      /*) printf '%s\n' "$configured" ;;
      *)  printf '%s/%s\n' "$root" "$configured" ;;
    esac
    return 0
  fi
  if [ -f "$root/.env.act" ]; then printf '%s\n' "$root/.env.act"; return 0; fi
  # A Node project usually has no .env of its own, so the project file is safe
  # to read. A Laravel project's .env is not.
  if [ -f "$root/.env" ] && [ ! -f "$root/composer.json" ]; then printf '%s\n' "$root/.env"; return 0; fi
  printf '%s\n' "$root/.env.act"
}

# ci_act_secret_file <root> — the secrets file act should read, if any.
ci_act_secret_file() {
  local root="${1:-$PWD}" configured
  configured="$(ci_config 'config.act && config.act.secretFile' ".secrets")"
  case "$configured" in
    /*) printf '%s\n' "$configured" ;;
    *)  printf '%s/%s\n' "$root" "$configured" ;;
  esac
}

# ci_docker_host — the Docker endpoint this machine talks to.
# OrbStack, Colima, Rancher Desktop and Docker Desktop with a non-default
# socket do not use /var/run/docker.sock, and act needs to be told.
ci_docker_host() {
  if [ -n "${DOCKER_HOST:-}" ]; then
    printf '%s\n' "$DOCKER_HOST"
    return 0
  fi
  if ci_have docker; then
    docker context inspect --format '{{ .Endpoints.docker.Host }}' 2>/dev/null | head -1
  fi
}

# ci_act_run [workflow-file] [job] [-- extra act flags]
ci_act_run() {
  local root="${CI_ROOT:-$PWD}" workflow="" job=""
  [ "$#" -gt 0 ] && case "$1" in -*) ;; *) workflow="$1"; shift ;; esac
  [ "$#" -gt 0 ] && case "$1" in -*) ;; *) job="$1"; shift ;; esac

  ci_require act "Install act: brew install act"
  [ -d "$root/.github/workflows" ] || ci_die "no .github/workflows directory in $root"

  # Point act at the same daemon the docker CLI talks to.
  local docker_host
  docker_host="$(ci_docker_host)"
  if [ -n "$docker_host" ]; then
    export DOCKER_HOST="$docker_host"
  fi

  # The architecture is left to the Docker daemon's default, which is what
  # act does anyway and what works with Podman and Colima too.
  local -a args=(--bind --pull=false)
  args+=(--env-file "$(ci_act_env_file "$root")")

  local secret_file
  secret_file="$(ci_act_secret_file "$root")"
  [ -f "$secret_file" ] && args+=(--secret-file "$secret_file")

  # act mounts /var/run/docker.sock into the container by default. When the
  # daemon listens somewhere else, that mount has to point at the real socket.
  case "$docker_host" in
    unix://*)
      local socket="${docker_host#unix://}"
      if [ "$socket" != "/var/run/docker.sock" ]; then
        args+=(--container-daemon-socket "unix://${socket}")
      fi
      ;;
  esac

  # Only force a platform image when neither the repository nor the home
  # directory already maps one.
  if ! grep -qE '^[[:space:]]*-P[[:space:]]' "$root/.actrc" 2>/dev/null \
     && ! grep -qE '^[[:space:]]*-P[[:space:]]' "$HOME/.actrc" 2>/dev/null; then
    args+=(-P "ubuntu-latest=$(ci_act_image)")
  fi

  [ -n "$workflow" ] && args+=(-W "$root/.github/workflows/$workflow")
  [ -n "$job" ] && args+=(-j "$job")

  ci_section "act ${workflow:+(workflow: $workflow) }${job:+(job: $job) }"
  (cd "$root" && act "${args[@]}" "$@")
}

# ci_act_list [root] — print the workflows and their jobs.
ci_act_list() {
  local root="${CI_ROOT:-$PWD}" wf jobs
  while IFS= read -r wf; do
    [ -z "$wf" ] && continue
    printf '\n%s%s%s\n' "$C_BOLD" "$wf" "$C_RESET"
    jobs="$(ci_workflow_jobs "$root/.github/workflows/$wf")"
    if [ -z "$jobs" ]; then
      printf '  (no jobs found)\n'
    else
      printf '%s\n' "$jobs" | sed 's/^/  - /'
    fi
  done < <(ci_list_workflows "$root")
}
