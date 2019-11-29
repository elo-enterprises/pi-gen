# Standard boilerplate
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -euxo pipefail -c
.DEFAULT_GOAL := provision

THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))
THIS_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`
SRC_ROOT := $(shell dirname ${THIS_MAKEFILE})

ANSIBLE_ROOT ?= ${SRC_ROOT}/ansible
export ANSIBLE_ROOT

ANSIBLE_LIBRARY ?= ${ANSIBLE_ROOT}/library
ANSIBLE_INVENTORY ?= ${ANSIBLE_ROOT}/inventory

ANSIBLE_VARS_BASE = ${ANSIBLE_ROOT}/vars-common.yml
ANSIBLE_ROLES_PATH = ${SRC_ROOT}/roles

ANSIBLE_CONFIG := ${ANSIBLE_ROOT}/ansible.cfg
ANSIBLE_GALAXY_REQUIREMENTS = ${ANSIBLE_ROLES_PATH}/requirements.yml
export ANSIBLE_CONFIG ANSIBLE_ROLES_PATH ANSIBLE_INVENTORY

ANSIBLE_INVENTORY = ${ANSIBLE_ROOT}/inventory
ANSIBLE_FACT_TREE:=${SRC_ROOT}/.facts
ANSIBLE_VAULT_FILES_PATTERN := .*vault.*
export ANSIBLE_USER ANSIBLE_FACT_TREE

# this is needed for interaction with SSM
# https://github.com/ansible/ansible/issues/32499
AWS_PROFILE=CHANGEME
export AWS_PROFILE
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

# NO_COLOR:=\033[0m
# WARN_COLOR:=\033[93m
# COLOR_GREEN=\033[92m
# COLOR_YELLOW=${WARN_COLOR}
# define _announce_make_target
#         @printf "$(COLOR_GREEN)(`hostname`) [target]:$(NO_COLOR) $@\n" 1>&2
# endef
# define _announce_assert
#         @printf "$(COLOR_YELLOW)(`hostname`) [${1}]:$(NO_COLOR) (=$2)\n" 1>&2;
# endef
# define _assert_var
#         @if [ "${${*}}" = "" ]; then \
#                 echo "Environment variable $* is not set" 1>&2; \
#                 exit 1; \
#         fi
# endef
# assert-%:
# 	$(call _announce_assert, $@, ${${*}})
# 	$(call _assert_var, $*)

DEPLOY_DIR:=deploy
SD_CARD:=/dev/disk2
export SD_CARD
export PI_GEN_REPO="https://github.com/elo-enterprises/pi-gen"
export DEPLOY_IMAGE:=${DEPLOY_DIR}/2019-11-29-elo-lite.img

build:
	PRESERVE_CONTAINER=1 CONTINUE=1 bash -x ./build-docker.sh -c elo.config

clean:
	rm -rf ${SRC_ROOT}/${DEPLOY_DIR}/

describe-artifacts:
	@printf "\n\n------------ BUILD ARTIFACTS (under '${DEPLOY_DIR}') ------------\n\n"
	du -hs ${DEPLOY_DIR}
	tree ${DEPLOY_DIR}/
	@printf 'zip files:'
	@tree ${DEPLOY_DIR}/|grep .zip
	@printf 'img files:'
	@tree ${DEPLOY_DIR}/|grep .img
	@printf 'local disks summary:'

describe-targets:
	@printf "\n\n------------ LOCAL DISK SUMMARY (for deployment targetting) ------------\n\n"
	diskutil list

describe:
	@printf "\n\n------------ PI-BUILDER SUMMARY ------------\n\n"
	make \
	describe-artifacts \
	describe-targets

push:
	export image=$(value DEPLOY_IMAGE) \
	;  echo "using $${image}" \
	&& ls $$image \
	&& du -h $(value DEPLOY_IMAGE) \
	&& sudo dd bs=1m if=$${image} of=$${image} conv=sync \
	&& sudo diskutil eject $(value SD_CARD)
