SHELL := /bin/sh

AWS_PROFILE ?= admin
AWS_REGION ?= us-east-2
DISCOVERY_DIR ?= .aws-discovery
WORKSPACE ?= workspace/personal/template-monorepo
ENVIRONMENT ?= development
OUTPUT_DIR := dist/$(patsubst workspace/%,%,$(WORKSPACE))/infra
TFVARS ?= $(WORKSPACE)/environments/$(ENVIRONMENT)/terraform.tfvars
BACKEND_CONFIG ?= $(WORKSPACE)/environments/$(ENVIRONMENT)/backend.tfbackend
LOCAL_BACKEND ?= false
PLAN_FILE ?= $(OUTPUT_DIR)/$(ENVIRONMENT).tfplan
REGISTRY_PLAN_FILE ?= $(OUTPUT_DIR)/$(ENVIRONMENT)-registry.tfplan
VALIDATE_DATA_DIR ?= $(abspath $(OUTPUT_DIR)/.terraform-validate)
EXTRA_TFVARS ?=

.PHONY: help discover export prepare fmt validate check-config bootstrap-registry plan apply destroy destroy-unsafe

help:
	@printf '%s\n' \
	  'make discover                         Discover account metadata' \
	  'make export WORKSPACE=workspace/...   Export a workspace blueprint' \
	  'make plan WORKSPACE=workspace/... ENVIRONMENT=development [LOCAL_BACKEND=true]' \
	  'make bootstrap-registry WORKSPACE=workspace/... ENVIRONMENT=development' \
	  'make apply WORKSPACE=workspace/... ENVIRONMENT=development [LOCAL_BACKEND=true]' \
	  'make destroy WORKSPACE=workspace/... ENVIRONMENT=development' \
	  'make destroy-unsafe WORKSPACE=workspace/... ENVIRONMENT=development' \
	  'make fmt                              Format Terraform blueprints/modules' \
	  'make validate                          Validate the template-monorepo export'

discover:
	./scripts/discover-aws.sh "$(AWS_PROFILE)" "$(AWS_REGION)" "$(DISCOVERY_DIR)"

export:
	./scripts/export-infra.sh "$(WORKSPACE)"

prepare:
	@test -d "$(OUTPUT_DIR)" || ./scripts/export-infra.sh "$(WORKSPACE)"

fmt:
	terraform fmt -recursive blueprints modules

validate: prepare
	TF_DATA_DIR=$(VALIDATE_DATA_DIR) terraform -chdir=$(OUTPUT_DIR) init -backend=false
	TF_DATA_DIR=$(VALIDATE_DATA_DIR) terraform -chdir=$(OUTPUT_DIR) validate

check-config:
	@test -f "$(TFVARS)" || { \
	  printf '%s\n' "Missing $(TFVARS). Copy the tfvars example first." >&2; \
	  exit 1; \
	}
	@test "$(LOCAL_BACKEND)" = true || test -f "$(BACKEND_CONFIG)" || { \
	  printf '%s\n' "Missing $(BACKEND_CONFIG). Copy the tfbackend example first." >&2; \
	  exit 1; \
	}

bootstrap-registry: prepare check-config
	@if [ "$(LOCAL_BACKEND)" = true ]; then terraform -chdir=$(OUTPUT_DIR) init; else terraform -chdir=$(OUTPUT_DIR) init -backend-config=$(abspath $(BACKEND_CONFIG)); fi
	terraform -chdir=$(OUTPUT_DIR) plan -var-file=$(abspath $(TFVARS)) $(if $(EXTRA_TFVARS),-var-file=$(abspath $(EXTRA_TFVARS))) -target=module.registry -out=$(abspath $(REGISTRY_PLAN_FILE))
	terraform -chdir=$(OUTPUT_DIR) apply $(abspath $(REGISTRY_PLAN_FILE))

plan: prepare check-config
	@if [ "$(LOCAL_BACKEND)" = true ]; then terraform -chdir=$(OUTPUT_DIR) init; else terraform -chdir=$(OUTPUT_DIR) init -backend-config=$(abspath $(BACKEND_CONFIG)); fi
	terraform -chdir=$(OUTPUT_DIR) plan -var-file=$(abspath $(TFVARS)) $(if $(EXTRA_TFVARS),-var-file=$(abspath $(EXTRA_TFVARS))) -out=$(abspath $(PLAN_FILE))

apply: prepare check-config
	@test -f "$(PLAN_FILE)" || { printf '%s\n' "Missing saved plan $(PLAN_FILE). Run make plan first." >&2; exit 1; }
	@if [ "$(LOCAL_BACKEND)" = true ]; then terraform -chdir=$(OUTPUT_DIR) init; else terraform -chdir=$(OUTPUT_DIR) init -backend-config=$(abspath $(BACKEND_CONFIG)); fi
	terraform -chdir=$(OUTPUT_DIR) apply $(abspath $(PLAN_FILE))

destroy: prepare check-config
	@if [ "$(LOCAL_BACKEND)" = true ]; then terraform -chdir=$(OUTPUT_DIR) init; else terraform -chdir=$(OUTPUT_DIR) init -backend-config=$(abspath $(BACKEND_CONFIG)); fi
	terraform -chdir=$(OUTPUT_DIR) destroy -var-file=$(abspath $(TFVARS))

destroy-unsafe: prepare check-config
	@if [ "$(LOCAL_BACKEND)" = true ]; then terraform -chdir=$(OUTPUT_DIR) init; else terraform -chdir=$(OUTPUT_DIR) init -backend-config=$(abspath $(BACKEND_CONFIG)); fi
	terraform -chdir=$(OUTPUT_DIR) destroy -auto-approve -var-file=$(abspath $(TFVARS))
