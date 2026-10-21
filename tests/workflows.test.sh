#!/usr/bin/env bash
test_workflows() {
  make_tmp
  mkdir -p "$TEST_TMP/.github/workflows"
  cat > "$TEST_TMP/.github/workflows/ci.yml" <<'YAML'
name: CI
on:
  push:
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - run: composer lint
  test:
    needs: lint
    runs-on: ubuntu-latest
    steps:
      - run: composer test
YAML
  assert_eq "ci.yml" "$(ci_list_workflows "$TEST_TMP")" "the workflow is found"
  assert_eq "lint test" \
    "$(ci_workflow_jobs "$TEST_TMP/.github/workflows/ci.yml" | tr '\n' ' ' | sed 's/ $//')" \
    "the jobs are found"
}
