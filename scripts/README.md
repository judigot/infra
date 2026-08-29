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

`dist/` is generated and ignored by Git.
