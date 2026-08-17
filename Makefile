SHELL := /bin/bash

REPO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ifeq ($(origin TASKSPEC_BIN),undefined)
TASKSPEC_BIN := $(if $(CVG_TASKSPEC_BIN),$(CVG_TASKSPEC_BIN),taskspec)
endif
ifeq ($(origin SEAMWISE_BIN),undefined)
SEAMWISE_BIN := $(if $(CVG_SEAMWISE_BIN),$(CVG_SEAMWISE_BIN),seamwise)
endif
PYTHON ?= python3

export CVG_TASKSPEC_BIN := $(TASKSPEC_BIN)
export CVG_SEAMWISE_BIN := $(SEAMWISE_BIN)
export PYTHONDONTWRITEBYTECODE := 1

.PHONY: check check-core check-json check-docs check-composed check-package \
	check-cockpit check-live-evidence demo-composed release-check

check: check-core check-json check-docs check-composed check-package

check-core:
	bash skills/task-to-runtime-contract/tests/run-tests.sh
	bash skills/task-specs-to-issues/tests/test-register.sh
	bash tests/test-cvg-snapshot.sh
	bash tests/test-cvg-doctor-plugin.sh
	bash tests/test-cvg-doctor-host.sh
	bash tests/test-cvg-doctor-evidence.sh
	bash tests/test-cvg-tasks-plan.sh
	bash tests/test-cvg-tasks-dod.sh
	bash tests/test-cvg-lesson.sh
	bash tests/test-install.sh
	bash tests/test-clean-room-install-e2e.sh
	bash tests/test-loop-kernel.sh
	bash tests/test-codex-engine.sh
	bash tests/test-version-unity.sh
	bash skills/idea-to-brd/tests/run-tests.sh
	bash skills/brd-docs-to-tech-req/tests/run-tests.sh
	bash skills/tech-req-to-adrs/tests/run-tests.sh
	bash skills/reqs-to-swimlane-plans/tests/run-tests.sh
	bash skills/sketch-plans-adversarial-review/tests/run-tests.sh
	bash skills/pass-to-lesson/tests/run-tests.sh
	bash skills/skill-creator/tests/test-skill-creator.sh
	bash skills/evidence-to-next-pass/tests/run-tests.sh
	python3 skills/task-to-runtime-contract/tests/test-gate-policy.py
	bash tests/test-ci-covers-every-suite.sh

check-json:
	bash tests/test-cvg-json-envelope.sh
	$(PYTHON) tests/test-cvg-json-matrix.py

check-docs:
	bash tests/test-docs.sh

check-composed:
	bash tests/test-compose.sh

check-package:
	bash tests/test-package.sh

check-cockpit:
	npm run cockpit:check
	npm run cockpit:build

check-live-evidence:
	$(PYTHON) scripts/validate-live-evidence.py

demo-composed:
	bash scripts/demo-composed.sh

release-check: check check-cockpit demo-composed check-live-evidence
