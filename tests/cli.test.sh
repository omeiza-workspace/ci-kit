#!/usr/bin/env bash
test_cli() {
  assert_eq "$(ci_kit_version)" "$("$KIT_ROOT/bin/ci" version)" "the version is printed"
  assert_true "$KIT_ROOT/bin/ci" help "help works"
  assert_true "$KIT_ROOT/bin/ci" config "config works"
  assert_false "$KIT_ROOT/bin/ci" not-a-command "an unknown command fails"
}

test_scaffold() {
  make_tmp
  mkdir -p "$TEST_TMP/repo"
  (
    cd "$TEST_TMP/repo" || exit 1
    git init -q .
    "$KIT_ROOT/bin/ci" init >/dev/null
  )

  assert_file "$TEST_TMP/repo/Makefile" "a Makefile is created"
  assert_file "$TEST_TMP/repo/.ci/ci.mk" "the shim is created"
  assert_file "$TEST_TMP/repo/.actrc" "the act config is created"
  assert_file "$TEST_TMP/repo/.ci/ci.json" "the config is created"

  # The shim must find the kit wherever it lives, which is what CI_KIT is for.
  assert_cmd "make help works through the shim" \
    make -C "$TEST_TMP/repo" CI_KIT="$KIT_ROOT" help
  assert_cmd "the ci target resolves" \
    make -C "$TEST_TMP/repo" CI_KIT="$KIT_ROOT" -n ci
}
