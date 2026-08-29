# Workspace

Application workspaces managed by this repository.

```text
<scope>/<app>/
├── blueprint
├── app/                 # ignored local clone
└── environments/
    ├── development/
    ├── staging/
    └── production/
```

`blueprint` contains a repository-relative blueprint reference such as `app/aws` or `app-database/aws`.

Environment directories contain only Terraform variable files. Real `*.tfvars` are ignored; commit safe `terraform.tfvars.example` files only.

The `app/` directory is an ordinary ignored clone of the application's source repository. It is not a Git submodule and is not part of the infrastructure export.
