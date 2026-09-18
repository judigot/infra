# Scripts

Repository automation for building and exporting application infrastructure.

## `discover-aws.sh`

Reads non-secret account metadata using the selected AWS CLI profile, writes
JSON inventory files, and prints a concise summary with tables. It does not
print or store credentials.

```sh
make discover
```

The output directory contains account, DNS, networking, ECR, CloudTrail,
GuardDuty, Security Hub, EC2, RDS, S3 bucket, and Terraform state-object discovery results, plus
value-oriented files such as `dns-values.json`, `vpc-values.json`, `subnet-values.json`, and
`availability-zone-values.json`. Route 53 record sets are stored per hosted
zone under `dns-records/`. The terminal output includes DNS records, IDs,
CIDRs, nameservers, and availability zones an engineer commonly needs for tfvars.
S3 state discovery records object metadata under `s3-tfstate/`; it never
downloads Terraform state contents because state can contain secrets.
Review it before applying a `config-*` or application blueprint.

## `export-infra.sh`

Materializes a workspace into standalone Terraform suitable for the application's own repository.

```sh
./scripts/export-infra.sh workspace/client-a/app-1
```

The argument is the workspace path relative to the repository root.

Output:

```text
dist/client-a/app-1/infra/
├── modules/
├── environments/
├── *.tf
└── README.md
```

The script materializes the workspace's selected blueprint as root Terraform files, rewrites local module paths, copies only referenced modules, and copies only committed-safe environment variable examples. Real `*.tfvars` files and unrelated repository content are not exported.

To use an exported environment, create its real variable file from the example and pass it to the root Terraform configuration:

```sh
cp dist/client-a/app-1/infra/environments/development/terraform.tfvars.example \
  dist/client-a/app-1/infra/environments/development/terraform.tfvars

terraform -chdir=dist/client-a/app-1/infra init
terraform -chdir=dist/client-a/app-1/infra plan \
  -var-file=environments/development/terraform.tfvars
```

`dist/` is generated and ignored by Git.
