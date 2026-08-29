# Deployments

Per-client, per-app, per-environment deployment configuration.

Expected layout:

```text
<client>/<app>/<environment>/config.tfvars
```

Real `.tfvars` files are ignored by Git because they may contain sensitive values.
