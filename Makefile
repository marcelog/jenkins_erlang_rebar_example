CWD=$(shell pwd)
NAME?=$(shell basename ${CWD})
ROOT?=${CWD}
APP_DIR=${ROOT}/apps/${NAME}
VM_ARGS?=${ROOT}/rel/files/vm.args
CONFIG?=${ROOT}/rel/files/dev.config
PROD_CONFIG?=${ROOT}/rel/files/prod.config
TEST_CONFIG?=${APP_DIR}/test/resources/test
TEST_VM_ARGS?=${APP_DIR}/test/resources/vm.args
DEPS=$(wildcard ${ROOT}/deps/*/ebin)
APPS=$(wildcard ${ROOT}/apps/*/ebin)
HOST?=${NAME}.local
NODE?=${NAME}@${HOST}
CT_LOG=${APP_DIR}/logs/ct
REBAR?=${ROOT}/rebar -j 4
COOKIE?=${NAME}
ERL?=/usr/bin/env erl
ERLARGS=-pa ${DEPS} -pa ${APPS} -smp enable -name ${NODE} \
	-setcookie ${COOKIE} -boot start_sasl \
	-config ${CONFIG} -args_file ${VM_ARGS} -s lager
TEST_ERL_ARGS?=${ERLARGS} -args_file ${TEST_VM_ARGS} -config ${TEST_CONFIG}
DIALYZER?=/usr/bin/env dialyzer
DIALYZER_OUT=${NAME}.plt
COVERTOOL?=deps/covertool/covertool
XREF_OUT=${CT_LOG}/xref.txt

ifdef CT_SUITES
	CT_SUITES_="suites=${CT_SUITES}"
else
	CT_SUITES_=""
endif
ifdef CT_CASE
	CT_CASE_="case=${CT_CASE}"
else
	CT_CASE_=""
endif


all: clean getdeps compile release

# Clean all.
clean:
	@${REBAR} clean

# Gets dependencies.
getdeps:
	@${REBAR} get-deps

# Compiles.
compile:
	@${REBAR} compile

# Dialyzer plt
${DIALYZER_OUT}:
	${DIALYZER} --verbose --build_plt -pa ${DEPS} --output_plt ${DIALYZER_OUT} \
		--apps kernel \
		stdlib \
		erts \
		compiler \
		hipe \
		crypto \
		edoc \
		gs \
		syntax_tools \
		tools \
		runtime_tools \
		inets \
		xmerl \
		ssl \
		mnesia \
		webtool

# Runs Dialyzer
analyze: compile ${DIALYZER_OUT} xref
	${DIALYZER} --verbose -pa ${DEPS} --plt ${DIALYZER_OUT} -Werror_handling \
		`find ${APP_DIR} -type f -name "${NAME}*.beam" | grep -v SUITE`

# Runs xref
xref:
	${REBAR} skip_deps=true xref

# Generates doc
doc:
	${REBAR} skip_deps=true doc 

# Creates the rebar node.
node:
	(mkdir -p rel && pushd rel && ${REBAR} create-node nodeid=${NAME} && popd)

# Creates a release.
release:
	@echo 'Generating ${NAME} release'
	@(mkdir -p rel && pushd rel && ${REBAR} generate && popd)

# Runs the release, no console.
run:
	${ROOT}/rel/${NAME}/bin/${NAME} start

# Cleans, recompiles, runs a console on the release.
allconsole: all runconsole

# Runs a release with a console.
runconsole:
	${ROOT}/rel/${NAME}/bin/${NAME} console

# This one runs without a release.
shell: compile
	${ERL} ${ERLARGS} -s ${NAME}

shellprod:
	make CONFIG=${PROD_CONFIG} shell

rshell:
	${ERL} -name remote@${HOST} -setcookie ${COOKIE} -remsh ${NODE}

detached: compile
	${ERL} ${ERLARGS} -noinput -noshell -s ${NAME}

detachedprod:
	make CONFIG=${PROD_CONFIG} detached

ci: getdeps compile test cobertura doc
	make xref > ${XREF_OUT}

# Intended to be run by a CI server.
test: compile #analyze
	@rm -rf ${CT_LOG}
	@mkdir -p ${CT_LOG}
	@find ${APP_DIR}/src -type f -exec cp {} ${APP_DIR}/ebin \;
	@find ${APP_DIR}/test -type f -exec cp {} ${APP_DIR}/ebin \;
	@ERL_FLAGS="${TEST_ERL_ARGS}" \
		ERL_AFLAGS="${TEST_ERL_ARGS}" \
		${REBAR} -v 3 skip_deps=true ${CT_SUITES_} ${CT_CASE_} ct
	@find ${APP_DIR}/ebin -type f -name "*.erl" -exec rm {} \;

covertool:
	@cd deps/covertool && make deps compile

cobertura: covertool
	@${COVERTOOL} -output ${APP_DIR}/logs/coverage.xml \
		-cover ${APP_DIR}/logs/cover.data -src ${APP_DIR}/src -appname ${NAME}

# If you're a dev, run this target instead of the one above: it will open
# the coverage results on your browser.
devtest: test
	@open ${CT_LOG}/index.html
