# Infrastructure Agent Instructions

## Required workflow

Read `README.md` before working in this repository. Run commands from the
repository root and use the root `Makefile` for discovery, export, plan, and
apply operations.

Never commit real `terraform.tfvars` files, credentials, or secrets. Review
generated discovery output before creating account or application resources.
Do not apply production changes without explicit user authorization.
