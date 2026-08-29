# Scripts

Repository automation for building and exporting application infrastructure.

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
