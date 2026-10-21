#!/usr/bin/env bash
test_paths() {
  assert_eq "$KIT_ROOT" "$(ci_kit_root)" "the kit knows where it is"
  assert_file "$KIT_ROOT/make/ci.mk" "the kit has its make targets"
  assert_file "$KIT_ROOT/lib/common.sh" "the kit has its libraries"
  assert_eq "$KIT_ROOT" "$(CI_KIT="$KIT_ROOT" ci_kit_locate)" "ci_kit_locate honours CI_KIT"
  assert_false ci_kit_locate "ci_kit_locate fails when there is no kit"
}
