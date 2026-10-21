#!/usr/bin/env bash
# Repository configuration for the kit: .ci/ci.json.
#
# Every field is optional. The file is read with node, which is a dependency
# the kit already has for reading package.json and composer.json.

# ci_config_path [root] — the configuration file for a repository, if it has one.
ci_config_path() {
  printf '%s/.ci/ci.json\n' "${1:-${CI_ROOT:-$PWD}}"
}

# ci_config <js-expression> [default] — evaluate an expression against the config.
# The config object is available as `config`.
ci_config() {
  local expr="$1" default="${2-}" file out=""
  file="$(ci_config_path)"
  [ -f "$file" ] || { printf '%s' "$default"; return 0; }
  out="$(node -e '
    const fs = require("fs");
    let config = {};
    try { config = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); } catch (e) { process.exit(0); }
    const value = (() => { try { return eval(process.argv[2]); } catch (e) { return undefined; } })();
    if (value === undefined || value === null) process.exit(0);
    process.stdout.write(typeof value === "string" ? value : JSON.stringify(value));
  ' "$file" "$expr" 2>/dev/null || true)"
  [ -n "$out" ] && printf '%s' "$out" || printf '%s' "$default"
}

# ci_config_services — the services 'ci services up' should start, if configured.
ci_config_services() {
  local raw
  raw="$(ci_config 'config.services ? config.services.join(" ") : ""')"
  [ -n "$raw" ] && printf '%s\n' "$raw"
}
