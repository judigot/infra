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
│   ├── app-database-postgresql/
│   ├── app-database-mysql/
│   ├── app-database-only-postgresql/
│   ├── app-database-only-mysql/
│   └── app-windows/
├── deployments/
├── hcp/
└── scripts/
```

`modules/` contains reusable provider-specific building blocks. `blueprints/` composes those capabilities into application architectures. `deployments/` contains per-client/app/environment configuration. `hcp/` contains HCP Terraform integration. `scripts/` contains repository automation.

## Legacy `judigot/terraform` migration

The old `package.json` commands represented deployment architectures. They now map to explicit blueprints instead of boolean switches:

| Old command | New blueprint |
| --- | --- |
| `dev` | `blueprints/app/aws` |
| `start` | `blueprints/app/aws` |
| `dev:db` | `blueprints/app-database/aws` |
| `start:db` | `blueprints/app-database/aws` |
| `start:db:postgresql` | `blueprints/app-database-postgresql/aws` |
| `start:db:mysql` | `blueprints/app-database-mysql/aws` |
| `db:postgresql` | `blueprints/app-database-only-postgresql/aws` |
| `db:mysql` | `blueprints/app-database-only-mysql/aws` |
| `windows` | `blueprints/app-windows/aws` |

`dev` and `start` share a blueprint because environment is deployment configuration, not architecture. The same applies to `dev:db` and `start:db`.

Terraform lifecycle and operator commands such as `init`, `plan`, `destroy`, `validate`, `fmt`, `output`, `ip`, `connect`, `logs`, `status`, `docker`, and `nginx` are operational concerns rather than blueprints.

Real `*.tfvars` files are intentionally ignored. Keep environment/client values under `deployments/` locally or in HCP Terraform workspace variables; only safe `*.tfvars.example` files belong in git.

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
