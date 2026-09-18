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

## Blueprint and module boundary

Production-oriented blueprints must compose reusable modules; do not place an
entire service architecture inline in a blueprint as a shortcut. Inline
resources are allowed only for explicitly labeled prototypes or temporary
experiments, and must be extracted into modules before the blueprint is treated
as production-ready.

This boundary matters because `scripts/export-infra.sh` copies only modules that
the selected blueprint references directly. A standalone export should contain
an `infra/modules/` directory whenever the blueprint uses reusable modules. If a
module depends on another local module, either reference and export that
dependency explicitly or extend the exporter to resolve transitive local
dependencies; never silently produce an incomplete application export.

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

The root `Makefile` is the supported entrypoint for discovery, export, plan,
and apply. It runs Terraform from `dist/` while protecting initialized exports
from accidental regeneration. Make targets refresh generated Terraform source
and referenced modules in place while preserving initialized backend data,
saved plans, and operator files. A manual export refuses to replace a directory
containing Terraform state, initialized provider files, real tfvars, or saved
plans. For ordinary regeneration it preserves the previous export in an
adjacent `infra.previous.*` directory rather than deleting it.
Review and remove these backups manually when they are no longer needed.

## Makefile workflow

Future agents should use the Makefile from the repository root instead of
invoking the scripts or Terraform commands directly:

```bash
make discover
make export WORKSPACE=workspace/personal/template-monorepo
make plan WORKSPACE=workspace/personal/template-monorepo ENVIRONMENT=development
make apply WORKSPACE=workspace/personal/template-monorepo ENVIRONMENT=development
```

Before `plan` or `apply`, create the real ignored variable file from the
exported example:

```bash
cp dist/personal/template-monorepo/infra/environments/development/terraform.tfvars.example \
  dist/personal/template-monorepo/infra/environments/development/terraform.tfvars
```

The Makefile supports `AWS_PROFILE`, `AWS_REGION`, `DISCOVERY_DIR`,
`WORKSPACE`, `ENVIRONMENT`, and `TFVARS` overrides. `make apply` remains an
interactive Terraform operation and requires valid AWS authentication.

Keep real environment values out of Git when they contain secrets. Each application/environment should use isolated Terraform state, such as a dedicated HCP Terraform workspace.

Configure that remote state isolation before using the example apply command.
Different `-var-file` arguments alone do not select different state; running all
environments against the same backend key would modify the same resources.

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
