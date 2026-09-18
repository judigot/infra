# Template monorepo infrastructure pipeline

Run the complete state-bootstrap and application deployment pipeline from any
working directory:

```bash
./workspace/personal/template-monorepo/apply.sh
ENVIRONMENT=staging ./workspace/personal/template-monorepo/apply.sh
```

The apply pipeline verifies the Terraform state bucket, creates it through the
`config-state` workspace when missing, bootstraps ECR, builds the Bun/Hono API,
pushes the commit-tagged image, records its immutable digest in an ignored
environment file, and applies the complete ECS deployment from a saved plan.
It then builds the Vite app with the Terraform API URL, publishes immutable
assets to a private S3 bucket, uploads non-cached HTML, and invalidates the
CloudFront distribution. The development environment serves the frontend at
`https://judigot.com`.
The image tag combines the Git revision and a source-content fingerprint, so
committed and in-progress application changes cannot collide in immutable ECR.
The Terraform apply is non-interactive.

Destroy an application environment with:

```bash
./workspace/personal/template-monorepo/destroy.sh
ENVIRONMENT=staging ./workspace/personal/template-monorepo/destroy.sh
```

Destroy uses the explicitly unsafe, non-interactive Make target. It removes the
application first and then deletes the state bucket and every version of every
state object without a confirmation prompt. This is irreversible and intended
only for disposable testing environments.
The pipeline first applies `force_destroy = true` to the state-bucket resource;
Terraform does not persist changed resource arguments automatically during a
destroy operation.
