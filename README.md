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

## Exporting application infrastructure

A workspace can be finalized into a standalone Terraform directory for its application repository:

```sh
./scripts/export-infra.sh workspace/client-a/app-1
```

The result is written to:

```text
dist/client-a/app-1/infra/
├── modules/
├── environments/
├── *.tf
└── README.md
```

The selected blueprint is materialized as root Terraform files. Only modules referenced by that blueprint are copied, so `blueprints/`, other workspaces, unused providers/modules, HCP integration, and repository tooling are not shipped to the application.

## Legacy `judigot/terraform` migration

The old package scripts mixed architecture selection with environment configuration. They map to the new model as follows:

| Old command | Architecture | Environment concern |
| --- | --- | --- |
| `dev` | `blueprints/app/aws` | development values |
| `start` | `blueprints/app/aws` | production values |
| `dev:db` | `blueprints/app-database/aws` | development values |
| `start:db` | `blueprints/app-database/aws` | production values |
| `start:db:postgresql` | `blueprints/app-database/aws` | `db_engine = "postgresql"` |
| `start:db:mysql` | `blueprints/app-database/aws` | `db_engine = "mysql"` |
| `db:postgresql` | `blueprints/database/aws` | `db_engine = "postgresql"` |
| `db:mysql` | `blueprints/database/aws` | `db_engine = "mysql"` |
| `windows` | `blueprints/app/aws` | `operating_system = "windows"` |

Terraform lifecycle commands such as `init`, `plan`, `destroy`, `validate`, `fmt`, and `output` are operational concerns rather than blueprints.

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
