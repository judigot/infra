# infra

Reusable, app-centric Terraform infrastructure blueprints.

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
├── deployments/
│   └── personal/
│       ├── dev-workstation/
│       │   └── development/
│       └── demo-app/
│           └── production/
├── hcp/
└── scripts/
```

`modules/` contains reusable provider-specific building blocks. `blueprints/` describes architecture/topology. `deployments/` selects a blueprint and supplies concrete app/environment configuration. `hcp/` contains HCP Terraform integration. `scripts/` contains repository automation.

## Design model

- **Module** = reusable implementation, such as AWS VPC, EC2, or RDS.
- **Blueprint** = architecture/topology, such as app, app + database, or database-only.
- **Deployment** = one concrete use of a blueprint for an app/environment.

Provider, region, operating system, instance type, database engine/version/class, disk sizing, CIDRs, and other environment-specific choices belong in deployments rather than becoming separate blueprint folders.

## Legacy `judigot/terraform` migration

The old package scripts mixed architecture selection with environment configuration. They now map to the new model:

| Old command | Architecture | Deployment concern |
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

Terraform lifecycle and operator commands such as `init`, `plan`, `destroy`, `validate`, `fmt`, `output`, `ip`, `connect`, `logs`, `status`, `docker`, and `nginx` are operational concerns rather than blueprints.

Real `*.tfvars` files are intentionally ignored. Deployment folders may contain committed non-secret Terraform root configuration and safe `*.tfvars.example` files, while real values stay local or in HCP Terraform workspace variables.

## Design checklist

- [ ] Cloud-provider agnostic — Supports AWS, Azure, and GCP.
- [ ] App deployment configuration — Infrastructure configured per application.
- [ ] Reusable infrastructure — Shared across clients and projects.
- [ ] Cross-provider deployment — Same app, same blueprint, different provider.
- [ ] HCP Terraform compatible — Supports remote Terraform workflows.
- [ ] Dynamic deployments — Select blueprint and provider through HCP Terraform API.
- [ ] Deployment state isolation — Separate Terraform state per deployment.
- [ ] Module ordering — Core dependencies first, optional integrations last.
- [ ] Standalone export — Finalize infra inside app repository.

## Blueprint file convention

`<number>-<category>-<capability>-<implementation>.tf`

Numbers exist only for visual ordering. Terraform still resolves dependencies declaratively.
