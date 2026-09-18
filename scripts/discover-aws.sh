#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 [profile] [region] [output-directory]" >&2
  exit 2
}

[ "$#" -le 3 ] || usage
profile=${1:-admin}
region=${2:-us-east-2}
output_dir=${3:-.aws-discovery}

command -v jq >/dev/null 2>&1 || { echo 'jq is required.' >&2; exit 1; }
command -v column >/dev/null 2>&1 || { echo 'column is required.' >&2; exit 1; }

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  bold=$(printf '\033[1m')
  cyan=$(printf '\033[36m')
  green=$(printf '\033[32m')
  dim=$(printf '\033[2m')
  reset=$(printf '\033[0m')
else
  bold=
  cyan=
  green=
  dim=
  reset=
fi

heading() {
  printf '\n%s%s%s%s\n' "$bold" "$cyan" "$1" "$reset"
}

case "$output_dir" in
  ""|/*|*..*|*//*|*" "*) echo "Invalid output directory: $output_dir" >&2; exit 2 ;;
esac

mkdir -p "$output_dir"
mkdir -p "$output_dir/dns-records"
mkdir -p "$output_dir/s3-tfstate"
aws_args="--profile $profile --region $region --output json"

run() {
  # shellcheck disable=SC2086
  aws $aws_args "$@"
}

run sts get-caller-identity > "$output_dir/account.json"
run route53 list-hosted-zones-by-name > "$output_dir/dns.json"
run ec2 describe-availability-zones --filters Name=state,Values=available > "$output_dir/availability-zones.json"
run ec2 describe-vpcs > "$output_dir/vpcs.json"
run ec2 describe-subnets > "$output_dir/subnets.json"
run ec2 describe-instances > "$output_dir/ec2-instances.json"
run rds describe-db-instances > "$output_dir/rds-instances.json"
run s3api list-buckets > "$output_dir/s3-buckets.json"
run ecr describe-repositories > "$output_dir/ecr.json"
run cloudtrail describe-trails > "$output_dir/cloudtrail.json"
run guardduty list-detectors > "$output_dir/guardduty.json"
run securityhub describe-hub > "$output_dir/securityhub.json" 2>/dev/null || printf '{"enabled":false}\n' > "$output_dir/securityhub.json"
for bucket_name in $(jq -r '.Buckets[].Name' "$output_dir/s3-buckets.json"); do
  bucket_key=$(printf '%s' "$bucket_name" | tr -c 'A-Za-z0-9._-' '_')
  run s3api get-bucket-location --bucket "$bucket_name" \
    > "$output_dir/s3-tfstate/$bucket_key-location.json" 2>/dev/null \
    || printf '{"status":"unavailable"}\n' > "$output_dir/s3-tfstate/$bucket_key-location.json"
  run s3api list-objects-v2 --bucket "$bucket_name" \
    --query 'Contents[?ends_with(Key, `.tfstate`) || ends_with(Key, `.tfstate.backup`)].{Key:Key,Size:Size,LastModified:LastModified}' \
    > "$output_dir/s3-tfstate/$bucket_key-objects.json" 2>/dev/null \
    || printf '{"status":"unavailable"}\n' > "$output_dir/s3-tfstate/$bucket_key-objects.json"
done
run route53 list-hosted-zones-by-name \
  --query 'HostedZones[].{Name:Name,Id:Id,NameServers:Config.NameServers}' \
  > "$output_dir/dns-values.json"
for hosted_zone_id in $(run route53 list-hosted-zones-by-name --query 'HostedZones[].Id' --output text | tr '\t' '\n'); do
  hosted_zone_key=${hosted_zone_id##*/}
  run route53 list-resource-record-sets --hosted-zone-id "$hosted_zone_id" \
    > "$output_dir/dns-records/$hosted_zone_key.json"
done
run ec2 describe-availability-zones \
  --filters Name=state,Values=available \
  --query 'AvailabilityZones[].ZoneName' \
  > "$output_dir/availability-zone-values.json"
run ec2 describe-vpcs \
  --query 'Vpcs[].{VpcId:VpcId,CidrBlock:CidrBlock,Default:IsDefault}' \
  > "$output_dir/vpc-values.json"
run ec2 describe-subnets \
  --query 'Subnets[].{SubnetId:SubnetId,VpcId:VpcId,Az:AvailabilityZone,CidrBlock:CidrBlock}' \
  > "$output_dir/subnet-values.json"

account_id=$(jq -r '.Account' "$output_dir/account.json")
identity_arn=$(jq -r '.Arn' "$output_dir/account.json")
printf '%s%sAWS discovery%s: profile=%s region=%s account=%s\n' "$bold" "$cyan" "$reset" "$profile" "$region" "$account_id"
printf '%sIdentity:%s %s\n' "$dim" "$reset" "$identity_arn"
printf '%sResources:%s zones=%s vpcs=%s ec2=%s rds=%s s3=%s ecr=%s trails=%s guardduty=%s\n' "$green" "$reset" \
  "$(jq '.HostedZones | length' "$output_dir/dns.json")" \
  "$(jq '.Vpcs | length' "$output_dir/vpcs.json")" \
  "$(jq '[.Reservations[].Instances[]] | length' "$output_dir/ec2-instances.json")" \
  "$(jq '.DBInstances | length' "$output_dir/rds-instances.json")" \
  "$(jq '.Buckets | length' "$output_dir/s3-buckets.json")" \
  "$(jq '.repositories | length' "$output_dir/ecr.json")" \
  "$(jq '.trailList | length' "$output_dir/cloudtrail.json")" \
  "$(jq '.DetectorIds | length' "$output_dir/guardduty.json")"

heading 'DNS zones'
{ printf 'NAME\tZONE_ID\n'; jq -r '.HostedZones[] | [.Name, (.Id|sub("^/hostedzone/";""))] | @tsv' "$output_dir/dns.json"; } | column -t -s "$(printf '\t')"
for record_file in "$output_dir"/dns-records/*.json; do
  [ -f "$record_file" ] || continue
  heading "DNS records ($(basename "$record_file" .json))"
  { printf 'TYPE\tNAME\tTTL\tVALUE\n'; jq -r '.ResourceRecordSets[] | [.Type,.Name,((.TTL // "-")|tostring),(if .ResourceRecords then (.ResourceRecords|map(.Value)|join(",")) elif .AliasTarget then .AliasTarget.DNSName else "-" end)] | @tsv' "$record_file"; } | column -t -s "$(printf '\t')"
done

heading 'Network'
printf 'Availability zones: %s\n' "$(jq -r '.AvailabilityZones | map(.ZoneName) | join(", ")' "$output_dir/availability-zones.json")"
{ printf 'VPC_ID\tCIDR\tDEFAULT\n'; jq -r '.Vpcs[] | [.VpcId,.CidrBlock,.IsDefault] | @tsv' "$output_dir/vpcs.json"; } | column -t -s "$(printf '\t')"
{ printf 'SUBNET_ID\tVPC_ID\tAZ\tCIDR\n'; jq -r '.Subnets[] | [.SubnetId,.VpcId,.AvailabilityZone,.CidrBlock] | @tsv' "$output_dir/subnets.json"; } | column -t -s "$(printf '\t')"

heading 'EC2 instances'
{ printf 'NAME\tINSTANCE_ID\tSTATE\tTYPE\tPRIVATE_IP\tPUBLIC_IP\n'; jq -r '.Reservations[].Instances[] | [([.Tags[]? | select(.Key=="Name") | .Value][0] // "-"),.InstanceId,.State.Name,.InstanceType,(.PrivateIpAddress // "-"),(.PublicIpAddress // "-")] | @tsv' "$output_dir/ec2-instances.json"; } | column -t -s "$(printf '\t')"

heading 'RDS instances'
{ printf 'IDENTIFIER\tENGINE\tVERSION\tCLASS\tSTATUS\tMULTI_AZ\tENDPOINT\n'; jq -r '.DBInstances[] | [.DBInstanceIdentifier,.Engine,.EngineVersion,.DBInstanceClass,.DBInstanceStatus,.MultiAZ,(.Endpoint.Address // "-")] | @tsv' "$output_dir/rds-instances.json"; } | column -t -s "$(printf '\t')"

heading 'S3 buckets and Terraform state'
{ printf 'BUCKET\tCREATED\n'; jq -r '.Buckets[] | [.Name,.CreationDate] | @tsv' "$output_dir/s3-buckets.json"; } | column -t -s "$(printf '\t')"
for bucket_name in $(jq -r '.Buckets[].Name' "$output_dir/s3-buckets.json"); do
  bucket_key=$(printf '%s' "$bucket_name" | tr -c 'A-Za-z0-9._-' '_')
  state_file="$output_dir/s3-tfstate/$bucket_key-objects.json"
  if jq -e 'type == "array" and length > 0' "$state_file" >/dev/null 2>&1; then
    printf 'State objects in %s:\n' "$bucket_name"
    { printf 'KEY\tSIZE\tLAST_MODIFIED\n'; jq -r '.[] | [.Key,.Size,.LastModified] | @tsv' "$state_file"; } | column -t -s "$(printf '\t')"
  fi
done
printf '\n%sJSON output:%s %s\n' "$dim" "$reset" "$output_dir"
