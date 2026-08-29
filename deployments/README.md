# Deployments

Concrete app/environment configuration. Every deployment has the same three environments:

```text
<scope>/<app>/
├── development/
├── staging/
└── production/
```

`default/` is the repository's basic AWS EC2 deployment and uses `blueprints/app/aws`.

Each environment should map to its own HCP Terraform workspace/state while sharing the deployment's architecture.

Real `.tfvars` files are ignored. Keep sensitive and environment-specific values in HCP Terraform workspace variables or ignored local files.
