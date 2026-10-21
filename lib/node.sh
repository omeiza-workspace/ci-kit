#!/usr/bin/env bash
# Node / Vue / Nuxt gates. Sourced by bin/ci.

# ci_node_script_name <package.json> <regex> — first script whose name matches.
ci_node_script_name() {
  ci_json_script_names "$1" "$2" | head -1
}

# ci_node_install [root]
ci_node_install() {
  local root="${1:-$PWD}"
  ci_require npm "Install Node.js (nvm, volta or asdf)."
  if [ -f "$root/package-lock.json" ]; then
    ci_run npm ci
  else
    ci_run npm install
  fi
}

# ci_node_version_pin <root> — the Node version this project expects, if declared.
ci_node_version_pin() {
  local root="${1:-$PWD}" v=""
  [ -f "$root/.nvmrc" ] && v="$(tr -d '[:space:]' < "$root/.nvmrc")"
  if [ -z "$v" ] && [ -f "$root/package.json" ]; then
    v="$(node -e '
      const fs=require("fs");
      try{const p=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
      process.stdout.write((p.engines&&p.engines.node)||(p.volta&&p.volta.node)||"");
      }catch(e){}' "$root/package.json" 2>/dev/null)"
  fi
  [ -n "$v" ] && printf '%s\n' "$v"
}

# ci_node_gates <root> [fast]
# Runs the gates the project actually has, in the order CI runs them.
ci_node_gates() {
  local root="${1:-$PWD}" fast="${2:-0}" rc=0 name=""
  local pkg="$root/package.json"

  ci_section "Node gates"

  if [ "$fast" != "1" ]; then
    ci_step "installing dependencies"
    ci_node_install "$root" || return 1
  fi

  # --- type check -------------------------------------------------------
  name="$(ci_node_script_name "$pkg" '^(type-check|typecheck|check-types|types)$')"
  if [ -n "$name" ]; then
    ci_step "type check (npm run $name)"
    npm run "$name" || rc=1
  elif [ -d "$root/node_modules/vue-tsc" ]; then
    ci_step "type check (vue-tsc --noEmit)"
    npx vue-tsc --noEmit || rc=1
  elif [ -f "$root/tsconfig.json" ] && [ -d "$root/node_modules/typescript" ]; then
    ci_step "type check (tsc --noEmit)"
    npx tsc --noEmit || rc=1
  else
    ci_dim "no type check declared — skipped"
  fi

  # --- lint -------------------------------------------------------------
  name="$(ci_node_script_name "$pkg" '^lint')"
  if [ -n "$name" ]; then
    ci_step "lint (npm run $name)"
    npm run "$name" || rc=1
  else
    ci_dim "no lint script — skipped"
  fi

  if [ "$fast" = "1" ]; then
    return $rc
  fi

  # --- tests ------------------------------------------------------------
  name="$(ci_node_script_name "$pkg" '^(test:unit|test:ci|test)$')"
  if [ -n "$name" ]; then
    ci_step "tests (npm run $name)"
    npm run "$name" || rc=1
  elif [ -d "$root/node_modules/vitest" ]; then
    ci_step "tests (vitest run)"
    npx vitest run || rc=1
  fi

  # --- build ------------------------------------------------------------
  name="$(ci_node_script_name "$pkg" '^build$')"
  if [ -n "$name" ]; then
    ci_step "build (npm run $name)"
    npm run "$name" || rc=1
  fi

  return $rc
}

# ci_nuxt_gates <root> [fast]
ci_nuxt_gates() {
  local root="${1:-$PWD}" fast="${2:-0}" rc=0

  ci_section "Nuxt gates"

  if [ "$fast" != "1" ]; then
    ci_step "installing dependencies"
    ci_node_install "$root" || return 1
  fi

  ci_step "type check (nuxt typecheck)"
  npx nuxt typecheck || rc=1

  if [ "$fast" = "1" ]; then
    return $rc
  fi

  ci_step "tests (vitest run)"
  npx vitest run || rc=1

  ci_step "build (nuxt build)"
  npx nuxt build || rc=1

  return $rc
}
