# Classic AWS app blueprint

This is the migrated form of the deployment workflow from `judigot/terraform`. It keeps the familiar script-driven combinations while moving the implementation into `judigot/infra`.

## Script mapping

- `bun run dev` — development EC2 app server
- `bun run dev:db` — development EC2 + RDS
- `bun run start` — production EC2 app server
- `bun run start:db` — production EC2 + default PostgreSQL RDS
- `bun run start:db:postgresql` — production EC2 + PostgreSQL
- `bun run start:db:mysql` — production EC2 + MySQL
- `bun run db:postgresql` — PostgreSQL without EC2
- `bun run db:mysql` — MySQL without EC2
- `bun run windows` — Windows EC2
- `bun run connect|logs|status|docker|nginx` — operational helpers for Linux EC2

The old repository used Terraform booleans as a pseudo-blueprint selector (`enable_ec2`, `create_database`, `db_engine`, `os`). Those controls are intentionally preserved here as a compatibility layer. New reusable infrastructure should continue to move toward explicit app-centric blueprints rather than adding more toggles to this directory.

## Hardening applied during migration

The capability set is preserved, but unsafe historical defaults are not: SSH and RDP are closed unless CIDRs are supplied, database ingress is closed by default, RDS is private by default, storage is encrypted, and secrets are expected through `TF_VAR_*` environment variables instead of committed tfvars.

Copy `.env.example` to `.env` for local script use. Do not commit `.env`.
