#!/usr/bin/env bash
test_stack() {
  make_tmp
  mkdir -p "$TEST_TMP/empty"

  mkdir -p "$TEST_TMP/node" && echo '{}' > "$TEST_TMP/node/package.json"
  assert_eq "node" "$(ci_detect_stacks "$TEST_TMP/node")" "package.json means node"

  mkdir -p "$TEST_TMP/nuxt" && echo '{}' > "$TEST_TMP/nuxt/package.json" && touch "$TEST_TMP/nuxt/nuxt.config.ts"
  assert_eq "nuxt" "$(ci_detect_stacks "$TEST_TMP/nuxt")" "nuxt.config means nuxt"

  mkdir -p "$TEST_TMP/php" && echo '{}' > "$TEST_TMP/php/composer.json"
  assert_eq "php" "$(ci_detect_stacks "$TEST_TMP/php")" "composer.json means php"

  mkdir -p "$TEST_TMP/go" && touch "$TEST_TMP/go/go.mod"
  assert_eq "go" "$(ci_detect_stacks "$TEST_TMP/go")" "go.mod means go"

  mkdir -p "$TEST_TMP/both" && echo '{}' > "$TEST_TMP/both/package.json" && echo '{}' > "$TEST_TMP/both/composer.json"
  assert_eq "node php" "$(ci_detect_stacks "$TEST_TMP/both" | tr '\n' ' ' | sed 's/ $//')" "both stacks are detected"

  assert_eq "" "$(ci_detect_stacks "$TEST_TMP/empty")" "an empty directory has no stacks"
}
