#!/usr/bin/env bash
# PHP / Laravel gates. Sourced by bin/ci.

# ci_php_install [root]
ci_php_install() {
  local root="${1:-$PWD}"
  ci_require composer "Install Composer."
  if [ -f "$root/composer.lock" ]; then
    ci_run composer install --prefer-dist --no-progress --no-interaction
  else
    ci_run composer install --no-interaction
  fi
}

# ci_php_laravel_setup <root> [env] — the .env / key / storage dance a Laravel app needs.
# Shared with the workflows through scripts/ci/setup-laravel.sh when present.
ci_php_laravel_setup() {
  local root="${1:-$PWD}"
  local env_file="${2:-$root/.env}"
  if [ -f "$root/scripts/ci/setup-laravel.sh" ]; then
    ci_run bash "$root/scripts/ci/setup-laravel.sh"
    return $?
  fi
  mkdir -p "$root/bootstrap/cache" \
    "$root/storage/app/public" "$root/storage/framework/cache/data" \
    "$root/storage/framework/sessions" "$root/storage/framework/views" "$root/storage/logs"
  if [ ! -f "$env_file" ] && [ -f "$root/.env.example" ]; then
    cp "$root/.env.example" "$env_file"
    ci_dim "created $env_file from .env.example"
  fi
  if [ -f "$root/artisan" ] && grep -q '^APP_KEY=' "$env_file" 2>/dev/null; then
    ci_run php "$root/artisan" key:generate --force
  fi
}

# ci_php_gates <root> [fast] — lint, static analysis, tests.
ci_php_gates() {
  local root="${1:-$PWD}" fast="${2:-0}" rc=0
  local composer_json="$root/composer.json"
  local bin="$root/vendor/bin"

  ci_section "PHP gates"

  if [ "$fast" != "1" ]; then
    ci_step "installing dependencies"
    ci_php_install "$root" || return 1
  fi

  # --- static analysis --------------------------------------------------
  if [ -x "$bin/phpstan" ]; then
    ci_step "static analysis (phpstan)"
    (cd "$root" && "$bin/phpstan" analyse --no-progress) || rc=1
  elif [ -n "$(ci_composer_script "$composer_json" 'analyse')" ]; then
    ci_step "static analysis (composer analyse)"
    (cd "$root" && composer analyse) || rc=1
  else
    ci_dim "no static analysis configured — skipped"
  fi

  # --- code style -------------------------------------------------------
  if [ -x "$bin/pint" ]; then
    ci_step "code style (pint --test)"
    (cd "$root" && "$bin/pint" --test) || rc=1
  elif [ -n "$(ci_composer_script "$composer_json" 'lint')" ]; then
    ci_step "code style (composer lint)"
    (cd "$root" && composer lint) || rc=1
  else
    ci_dim "no code style tool configured — skipped"
  fi

  if [ "$fast" = "1" ]; then
    return $rc
  fi

  # --- tests ------------------------------------------------------------
  if [ -x "$bin/pest" ]; then
    ci_step "tests (pest)"
    (cd "$root" && "$bin/pest") || rc=1
  elif [ -x "$bin/phpunit" ]; then
    ci_step "tests (phpunit)"
    (cd "$root" && "$bin/phpunit" --colors=never) || rc=1
  elif [ -n "$(ci_composer_script "$composer_json" 'test')" ]; then
    ci_step "tests (composer test)"
    (cd "$root" && composer test) || rc=1
  else
    ci_dim "no test runner configured — skipped"
  fi

  return $rc
}
