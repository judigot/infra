#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
environment=${ENVIRONMENT:-development}
app_workspace=workspace/personal/template-monorepo
state_workspace=workspace/personal/config-state
state_bucket=template-monorepo-terraform-state
state_destroy_tfvars="$state_workspace/environments/production/destroy.tfvars"

case "$environment" in
  development|staging|production) ;;
  *) printf 'Unsupported environment: %s\n' "$environment" >&2; exit 2 ;;
esac

cd "$repo_root"

printf 'Destroying template-monorepo %s resources...\n' "$environment"
make destroy-unsafe WORKSPACE="$app_workspace" ENVIRONMENT="$environment"

printf '\nWARNING: permanently deleting bucket %s and every Terraform state version in it.\n' "$state_bucket"

state_teardown_plan="dist/personal/config-state/infra/state-bucket-teardown.tfplan"

# Terraform destroy does not first persist changed resource arguments. Apply
# force_destroy=true to state before deletion so the provider removes every
# object version and delete marker from the versioned bucket.
make plan \
  WORKSPACE="$state_workspace" \
  ENVIRONMENT=production \
  LOCAL_BACKEND=true \
  TFVARS="$state_destroy_tfvars" \
  PLAN_FILE="$state_teardown_plan"
make apply \
  WORKSPACE="$state_workspace" \
  ENVIRONMENT=production \
  LOCAL_BACKEND=true \
  TFVARS="$state_destroy_tfvars" \
  PLAN_FILE="$state_teardown_plan"

make destroy-unsafe \
  WORKSPACE="$state_workspace" \
  ENVIRONMENT=production \
  LOCAL_BACKEND=true \
  TFVARS="$state_destroy_tfvars"

make discover >/dev/null
if jq -e --arg bucket "$state_bucket" '.Buckets[]? | select(.Name == $bucket)' .aws-discovery/s3-buckets.json >/dev/null; then
  printf 'State bucket still exists after destroy: %s\n' "$state_bucket" >&2
  exit 1
fi

printf '%s\n' 'Application resources and Terraform state bucket were destroyed.'
