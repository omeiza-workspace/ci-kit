# The kit's own targets. A repository that uses the kit does not need these.
#
#   make test   run the test suite
#   make lint   run ShellCheck over the kit
#   make check  both

.PHONY: test lint check clean

test: ## Run the test suite
	@tests/run.sh

lint: ## Run ShellCheck over the kit
	@tests/lint.sh

check: lint test ## Lint and test

clean: ## Remove what the local runs leave behind
	@rm -rf .act-artifacts
