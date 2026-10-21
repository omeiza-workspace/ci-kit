#!/usr/bin/env bash

test_mocks() {
  make_tmp
  mkdir -p "$TEST_TMP/.ci"
  cat > "$TEST_TMP/.ci/ci.json" <<'JSON'
{
  "mocks": {
    "command": "node bin/api-mock-services.js start paystack",
    "cwd": "../api-mock-services",
    "assert": false,
    "endpoints": {
      "paystack": "http://127.0.0.1:4005",
      "youverify": "http://127.0.0.1:4007"
    }
  }
}
JSON
  export CI_ROOT="$TEST_TMP"

  assert_eq "node bin/api-mock-services.js start paystack" \
    "$(CI_ROOT="$TEST_TMP" ci_mocks_config command)" \
    "the mock command is read"

  assert_eq "paystack=http://127.0.0.1:4005
youverify=http://127.0.0.1:4007" \
    "$(CI_ROOT="$TEST_TMP" ci_mocks_endpoints)" \
    "the endpoints are listed, one per line"

  # The url is split into a host and a port. A greedy split used to take the
  # port for the host, and every check failed.
  CI_ROOT="$TEST_TMP" ci_mocks_split "http://127.0.0.1:4005"
  assert_eq "127.0.0.1" "$MOCK_HOST" "the host is the part before the colon"
  assert_eq "4005" "$MOCK_PORT" "the port is the part after the colon"

  CI_ROOT="$TEST_TMP" ci_mocks_split "http://127.0.0.1:4007/health"
  assert_eq "127.0.0.1" "$MOCK_HOST" "a path does not confuse the host"
  assert_eq "4007" "$MOCK_PORT" "a path does not confuse the port"

  # The assertion is opt-in: a repository whose tests start the mocks
  # themselves has nothing to check.
  assert_cmd "the preflight passes when the assertion is off" \
    env CI_ROOT="$TEST_TMP" bash -c "source '$KIT_ROOT/lib/common.sh'; source '$KIT_ROOT/lib/config.sh'; source '$KIT_ROOT/lib/mocks.sh'; ci_mocks_assert"
}

test_versions() {
  assert_true ci_version_lt 0.2.68 0.2.86 "an older version compares as older"
  assert_false ci_version_lt 0.2.89 0.2.86 "a newer version does not"
  assert_false ci_version_lt 1.0.0 1.0.0 "the same version is not older"
}
