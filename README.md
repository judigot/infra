# infra

Reusable, app-centric Terraform infrastructure and workspace control plane.

## Repository structure

```text
infra/
├── modules/
│   ├── aws/
│   ├── azure/
│   └── gcp/
├── blueprints/
│   ├── app/
│   ├── app-database/
│   └── database/
├── workspace/
│   ├── default/
│   ├── personal/
│   └── client-a/
├── hcp/
└── scripts/
```

`modules/` contains reusable provider-specific building blocks. `blueprints/` describes architecture/topology and composes modules. `workspace/` contains concrete app workspaces and environment values. `hcp/` contains HCP Terraform integration. `scripts/` contains repository automation.

## Design model

- **Module** = reusable provider implementation, such as AWS VPC, EC2, or RDS.
- **Blueprint** = architecture/topology selected while building an application's infrastructure.
- **Workspace** = one application's working area, including its selected blueprint, ignored app clone, and environment configuration.
- **Deployment** = applying one workspace environment through Terraform/HCP Terraform.

Environment-specific values such as region, operating system, instance type, database engine/version/class, disk sizing, and CIDRs belong under `workspace/<scope>/<app>/environments/`.

Each environment directory contains only Terraform variable files. Real `*.tfvars` remain ignored; safe `terraform.tfvars.example` files document the expected values.

## Workspace layout

```text
workspace/<scope>/<app>/
├── blueprint
├── app/
└── environments/
    ├── development/
    │   └── terraform.tfvars.example
    ├── staging/
    │   └── terraform.tfvars.example
    └── production/
        └── terraform.tfvars.example
```

`blueprint` identifies the architecture/provider combination to materialize. `app/` is an ignored local clone of the application repository and is not part of this repository's source of truth. The environment directories contain only values that vary between deployments.

## Scripts

### Export infrastructure

Use `scripts/export-infra.sh` to turn a workspace into standalone, maintainable Terraform that can live inside the application repository.

```sh
./scripts/export-infra.sh workspace/client-a/app-1
```

The argument is the workspace path relative to the repository root. The generated artifact is written under `dist/` using the same scope and application name:

```text
dist/client-a/app-1/infra/
├── modules/
├── environments/
│   ├── development/
│   │   └── terraform.tfvars.example
│   ├── staging/
│   │   └── terraform.tfvars.example
│   └── production/
│       └── terraform.tfvars.example
├── *.tf
└── README.md
```

The exporter:

- materializes the selected blueprint as the root Terraform configuration;
- rewrites local module sources for the exported directory;
- copies only modules referenced by that blueprint;
- copies the workspace's committed-safe environment variable examples; and
- excludes unrelated blueprints, workspaces, providers, HCP integration, repository tooling, and real `*.tfvars` files.

`dist/` is ignored because it is generated output. Copy `dist/<scope>/<app>/infra/` into the target application's repository when the infrastructure definition is ready to be maintained with the application.

## Terraform usage

The exported `infra/` directory is self-contained. Select an environment by passing its variable file to the root Terraform configuration:

```sh
terraform -chdir=infra init
terraform -chdir=infra plan -var-file=environments/development/terraform.tfvars
terraform -chdir=infra apply -var-file=environments/development/terraform.tfvars
```

Keep real environment values out of Git when they contain secrets. Each application/environment should use isolated Terraform state, such as a dedicated HCP Terraform workspace.

## Design checklist

- [ ] Cloud-provider agnostic — Supports AWS, Azure, and GCP.
- [ ] App workspace configuration — Infrastructure configured per application.
- [ ] Reusable infrastructure — Shared across clients and projects.
- [ ] Cross-provider deployment — Same app, same blueprint, different provider.
- [ ] HCP Terraform compatible — Supports remote Terraform workflows.
- [ ] Dynamic deployments — Select blueprint and provider through HCP Terraform API.
- [ ] Environment state isolation — Separate Terraform state per app/environment.
- [ ] Module ordering — Core dependencies first, optional integrations last.
- [x] Standalone export — Materialize maintainable Terraform inside an app repository.

## Blueprint file convention

`<number>-<category>-<capability>-<implementation>.tf`

Numbers exist only for visual ordering. Terraform still resolves dependencies declaratively.
