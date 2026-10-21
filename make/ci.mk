# Shared make targets for the CI kit.
#
# A repository includes this through .ci/ci.mk, which locates the kit.
# Override CI_KIT on the command line to use a different checkout:
#   make CI_KIT=/path/to/ci-kit ci

CI_KIT ?= $(HOME)/.local/share/ci-kit
CI_BIN ?= $(CI_KIT)/bin/ci
CI := $(CI_BIN)

# A repository that already defines its own `help` or `ci` target sets
# CI_KIT_SKIP_COMMON=1 before the include, and keeps both.
CI_KIT_SKIP_COMMON ?= 0

.PHONY: ci-fast doctor act act-list services-up services-down services-status hooks-install hooks-uninstall env config

ifneq ($(CI_KIT_SKIP_COMMON),1)

.PHONY: help ci

help: ## Show the available targets
	@printf '\n\033[1;36mTargets\033[0m\n'
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@printf '\n'

ci: ## Run the full local CI gate (every stack in this repository)
	@$(CI) gate

endif

ci-fast: ## Run the fast gate — lint and type checks only, no installs or services
	@$(CI) gate --fast

doctor: ## Audit the toolchain against the versions the workflows pin
	@$(CI) doctor

config: ## Show the resolved configuration
	@$(CI) config

act: ## Run a workflow locally with act (make act W=file.yml J=job)
	@$(CI) act $(W) $(J) $(ACTFLAGS)

act-list: ## List the workflows and their jobs
	@$(CI) act-list

services-up: ## Start the local service containers
	@$(CI) services up $(SERVICES)

services-down: ## Stop the local service containers
	@$(CI) services down $(SERVICES)

services-status: ## Show the local service containers
	@$(CI) services status

hooks-install: ## Install the pre-push gate
	@$(CI) hooks install

hooks-uninstall: ## Remove the pre-push gate
	@$(CI) hooks uninstall

env: ## Show the env files that feed the local runs
	@$(CI) env
