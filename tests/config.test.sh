#!/usr/bin/env bash
test_config() {
  make_tmp
  mkdir -p "$TEST_TMP/.ci"
  cat > "$TEST_TMP/.ci/ci.json" <<'JSON'
{
  "stack": ["node", "php"],
  "services": ["mysql", "redis"],
  "act": { "image": "example/image:tag", "envFile": ".env.test" }
}
JSON
  assert_eq "example/image:tag" \
    "$(CI_ROOT="$TEST_TMP" ci_config 'config.act && config.act.image' 'default')" \
    "the act image is read"
  assert_eq "mysql redis" \
    "$(CI_ROOT="$TEST_TMP" ci_config_services | tr '\n' ' ' | sed 's/ $//')" \
    "the services are read"
  assert_eq "fallback" \
    "$(CI_ROOT="$TEST_TMP/nothing" ci_config 'config.act && config.act.image' 'fallback')" \
    "a missing config falls back"
}
