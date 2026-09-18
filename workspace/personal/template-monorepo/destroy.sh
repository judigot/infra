#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../../.." && pwd)
environment=${ENVIRONMENT:-development}
aws_profile=${AWS_PROFILE:-admin}
aws_region=${AWS_REGION:-us-east-2}
app_workspace=workspace/personal/template-monorepo
state_workspace=workspace/personal/config-state
state_bucket=template-monorepo-terraform-state
state_destroy_tfvars="$state_workspace/environments/production/destroy.tfvars"
repository_name="template-monorepo-$environment/api"
frontend_bucket_prefix="template-monorepo-$environment-frontend-"

case "$environment" in
  development|staging|production) ;;
  *) printf 'Unsupported environment: %s\n' "$environment" >&2; exit 2 ;;
esac

cd "$repo_root"

for command_name in aws jq make terraform; do
  command -v "$command_name" >/dev/null 2>&1 || {
    printf 'Required command is not installed: %s\n' "$command_name" >&2
    exit 1
  }
done

bucket_exists() {
  aws s3api head-bucket --bucket "$state_bucket" \
    --profile "$aws_profile" --region "$aws_region" >/dev/null 2>&1
}

purge_versioned_bucket() {
  bucket="$1"
  while :; do
    versions=$(aws s3api list-object-versions --bucket "$bucket" \
      --profile "$aws_profile" --region "$aws_region" --output json)
    delete_request=$(printf '%s' "$versions" | jq -c \
      '{Objects: ([.Versions[]?, .DeleteMarkers[]?] | map({Key, VersionId})), Quiet: true}')
    object_count=$(printf '%s' "$delete_request" | jq '.Objects | length')
    [ "$object_count" -gt 0 ] || break
    aws s3api delete-objects --bucket "$bucket" --delete "$delete_request" \
      --profile "$aws_profile" --region "$aws_region" >/dev/null
  done
}

delete_frontend_buckets() {
  buckets=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, '$frontend_bucket_prefix')].Name" \
    --output text --profile "$aws_profile" --region "$aws_region")
  for bucket in $buckets; do
    [ "$bucket" = None ] && continue
    purge_versioned_bucket "$bucket"
  done
}

printf 'Destroying template-monorepo %s resources...\n' "$environment"
aws ecr delete-repository --repository-name "$repository_name" --force \
  --profile "$aws_profile" --region "$aws_region" >/dev/null 2>&1 || true
delete_frontend_buckets
make destroy-unsafe WORKSPACE="$app_workspace" ENVIRONMENT="$environment" \
  AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region"

if bucket_exists; then
  printf 'Removing all Terraform state object versions and delete markers...\n'
  purge_versioned_bucket "$state_bucket"
  make destroy-unsafe WORKSPACE="$state_workspace" ENVIRONMENT=production \
    LOCAL_BACKEND=true TFVARS="$state_destroy_tfvars" \
    AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region"
fi

make discover AWS_PROFILE="$aws_profile" AWS_REGION="$aws_region" >/dev/null
if jq -e --arg bucket "$state_bucket" \
  '.Buckets[]? | select(.Name == $bucket)' .aws-discovery/s3-buckets.json >/dev/null; then
  printf 'State bucket still exists after destroy: %s\n' "$state_bucket" >&2
  exit 1
fi

printf '%s\n' 'Application resources and Terraform state bucket were destroyed.'
