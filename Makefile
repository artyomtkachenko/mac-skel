SHELL  := /bin/bash
.DEFAULT_GOAL := usage
RED    := \033[0;31m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
CYAN   := \033[0;36m
NC     := \033[0m # No Color

AWS_REGION  := ap-southeast-2
ECR_REGISTRY_ID := 123456789012
BUILD_TOOLS := $(ECR_REGISTRY_ID).dkr.ecr.ap-southeast-2.amazonaws.com/<changeme>
BUILD_TYPE ?= local

DOCKER_RUN := docker run \
--rm \
-w /docker \
-v $(CURDIR):/docker \
-v ${HOME}:${HOME} \
-e ANSIBLE_CONFIG=ansible/ansible.cfg \
-e AWS_PROFILE=${AWS_PROFILE} \
-e ENV=$(ENV) \
-e HOME=${HOME} \
-t $(BUILD_TOOLS)

usage:
	@printf "\n\n$(YELLOW)Usage:$(NC)\n\n"
	@printf "${YELLOW}make changeme $(CYAN)ENV=<foo,bar> ${GREEN}# Create/update changeme${NC}\n"
	@printf "\n"
	@exit 1

check-aws-profile:
	@test -n "$(AWS_PROFILE)" || (printf "\n\n\n${RED}AWS_PROFILE${NC}var is not defined. AWS profile name can be found in ~/.aws/credentials ${NC}\n\n\n" && exit 1)

docker-login:
	$(eval DOCKER_LOGIN = $(shell aws ecr get-login --no-include-email --registry-ids $(ECR_REGISTRY_ID) --region ${AWS_REGION}))

build-tools: docker-login
	eval $(DOCKER_LOGIN); \
	docker pull $(BUILD_TOOLS)

local-changeme: check-aws-profile
	ansible-playbook -i '$(ENV),' ansible/playbooks/changeme.yml $(DEBUG)

docker-%:
	if [[ -z `docker images $(BUILD_TOOLS) --format '{{.ID}}'` ]]; then make build-tools; fi
	$(DOCKER_RUN) make $(subst docker,local,$@)

%: $(BUILD_TYPE)-%
	@true
