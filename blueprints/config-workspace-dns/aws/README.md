# Workspace DNS hosts

Manages EC2 workspace hostnames as CNAMEs to an existing public Route 53 zone
created by `config-dns/aws`.

Typical records:

- `dev.<domain>` — T3 / Metro / ops surfaces
- optionally `db.<domain>` — database viewer

Does not create the hosted zone. Point `workspace_cnames` at labels that are
not already managed elsewhere, or import existing records before applying.
