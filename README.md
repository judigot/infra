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
│   └── app/
│       └── aws/
│           └── classic/
├── deployments/
├── hcp/
│   ├── workspace/
│   └── api/
└── scripts/
```

`modules/` contains reusable provider-specific building blocks. `blueprints/` composes those capabilities into opinionated application architectures. `deployments/` contains per-client/app/environment configuration. `hcp/` contains HCP Terraform integration. `scripts/` contains repository automation.

## Classic workflow

The former `judigot/terraform` package-script workflow now lives in `blueprints/app/aws/classic`. The root `package.json` preserves the familiar commands (`dev`, `dev:db`, `start`, `start:db`, PostgreSQL/MySQL database-only variants, Windows, SSH helpers, Terraform lifecycle commands) while the infrastructure implementation lives in this repository.

The classic blueprint is a compatibility layer for the old toggle-driven workflow. New designs should favor explicit app-centric blueprints and reusable provider modules instead of accumulating more boolean switches.

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
