.DEFAULT_GOAL := check
.PHONY: check fmt-check fmt lint test

check:
	node scripts/quality.cjs check

fmt-check:
	node scripts/quality.cjs fmt-check

fmt:
	node scripts/quality.cjs fmt

lint:
	node scripts/quality.cjs lint

test:
	node --test
