#!/usr/bin/env bash
test_scripts() {
  make_tmp
  cat > "$TEST_TMP/package.json" <<'JSON'
{
  "name": "fixture",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "lint": "eslint src/",
    "type-check": "vue-tsc --noEmit",
    "test:unit": "vitest run"
  }
}
JSON
  assert_eq "vite build" "$(ci_json_script "$TEST_TMP/package.json" build)" "a script is read"
  assert_eq "" "$(ci_json_script "$TEST_TMP/package.json" nope)" "a missing script is empty"
  assert_eq "build lint" \
    "$(ci_json_script_names "$TEST_TMP/package.json" '^(build|lint)$' | tr '\n' ' ' | sed 's/ $//')" \
    "scripts are matched by name"

  cat > "$TEST_TMP/composer.json" <<'JSON'
{
  "name": "fixture/pkg",
  "scripts": {
    "test": "pest",
    "lint": "pint --test",
    "analyse": "phpstan analyse --level=8"
  }
}
JSON
  assert_eq "pest" "$(ci_composer_script "$TEST_TMP/composer.json" test)" "a composer script is read"
  assert_eq "lint" \
    "$(ci_composer_scripts "$TEST_TMP/composer.json" | head -2 | tail -1)" \
    "composer scripts are listed"
}
