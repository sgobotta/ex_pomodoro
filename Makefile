.PHONY: setup test

export MIX_ENV ?= dev

LOCAL_ENV_FILE = .env
PROD_ENV_FILE = .env.prod
APP_NAME = `grep 'APP_NAME=' .env | sed -e 's/\[//g' -e 's/ //g' -e 's/APP_NAME=//'`
DOCKER_BUILD_NAME = ${APP_NAME}_app

export GREEN=\033[0;32m
export NOFORMAT=\033[0m

default: help

#๐ check: @ Runs all code verifications
check: check.lint check.dialyzer test

#๐ check.dialyzer: @ Runs a static code analysis
check.dialyzer: SHELL:=/bin/bash
check.dialyzer:
	@source ${LOCAL_ENV_FILE} && mix check.dialyzer

#๐ check.lint: @ Strictly runs a code formatter
check.lint: SHELL:=/bin/bash
check.lint:
	@source ${LOCAL_ENV_FILE} && mix check.format
	@source ${LOCAL_ENV_FILE} && mix check.credo

#๐ docs: @ Generates HTML documentation
docs:
	@mix docs

#โ help: @ Displays this message
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "${GREEN}%-30s${NOFORMAT} %s\n", $$1, $$2}'

#๐ป lint: @ Formats code
lint: SHELL:=/bin/bash
lint:
	@source ${LOCAL_ENV_FILE} && mix format
	@source ${LOCAL_ENV_FILE} && mix check.credo

#๐ป publish: @ Publishes a package on Hex
publish: SHELL:=/bin/bash
publish:
	@mix hex.publish

#๐ฆ setup: @ Installs dependencies and set up database for dev and test envs
setup: SHELL:=/bin/bash
setup: setup.dev setup.test

#๐ฆ setup.dev: @ Installs dependencies and set up database for dev env
setup.dev: SHELL:=/bin/bash
setup.dev:
	@source ${LOCAL_ENV_FILE} && MIX_ENV=dev mix setup

#๐ฆ setup.test: @ Installs dependencies and set up database for test env
setup.test: SHELL:=/bin/bash
setup.test:
	@source ${LOCAL_ENV_FILE} && MIX_ENV=test mix setup

#๐งช test: @ Runs all test suites
test: MIX_ENV=test
test: SHELL:=/bin/bash
test:
	@source ${LOCAL_ENV_FILE} && mix test

#๐งช test.cover: @ Runs all tests and generates a coverage report
test.cover: MIX_ENV=test
test.cover: SHELL:=/bin/bash
test.cover:
	@source ${LOCAL_ENV_FILE} && mix coveralls.html

#๐งช test.cover.watch: @ Runs and watches all tests and generates a coverage report
test.cover.watch: SHELL:=/bin/bash
test.cover.watch:
	@echo "๐งช๐๏ธ  Watching all test suites with coverage..."
	@source ${LOCAL_ENV_FILE} && mix test.watch --cover

#๐งช test.cover.wip.watch: @ Runs and watches tests that matches the wip tag and generates a coverage report
test.cover.wip.watch: SHELL:=/bin/bash
test.cover.wip.watch:
	@echo "๐งช๐๏ธ  Watching test suites tagged with wip, with coverage..."
	@source ${LOCAL_ENV_FILE} && mix test.watch --cover --only wip

#๐งช test.watch: @ Runs and watches all test suites
test.watch: SHELL:=/bin/bash
test.watch:
	@echo "๐งช๐๏ธ  Watching all test suites..."
	@source ${LOCAL_ENV_FILE} && mix test.watch

#๐งช test.wip: @ Runs test suites that match the wip tag
test.wip: MIX_ENV=test
test.wip: SHELL:=/bin/bash
test.wip:
	@source ${LOCAL_ENV_FILE} && mix test --only wip

#๐งช test.wip.watch: @ Runs and watches test suites that match the wip tag
test.wip.watch: SHELL:=/bin/bash
test.wip.watch:
	@echo "๐งช๐๏ธ  Watching test suites tagged with wip..."
	@source ${LOCAL_ENV_FILE} && mix test.watch --only wip
