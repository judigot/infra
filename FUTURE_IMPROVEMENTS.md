# Future infrastructure improvements

This backlog prioritizes the reusable AWS modules and template-monorepo
blueprint. It records proposed work, not guarantees about the deployed
environment. Keep deployment-specific choices in workspace configuration and
pass them through blueprint inputs. Do not put credentials, live account
identifiers, or Terraform state in this document.

## Existing foundation

The modules already provide ECS deployment rollback, autoscaling, health
checks, private frontend storage with CloudFront origin access control, WAF
rules, ALB access logs, VPC flow logs, CloudWatch alarms, immutable ECR tags,
image scanning on push, and image retention. Future work should extend and
verify these controls rather than duplicate them. Their presence alone does
not establish production readiness.

## Priority 1: correctness and operational readiness

- [ ] **Order ALB logging dependencies explicitly.** Make the load balancer
  wait for the log bucket policy and required bucket configuration. Keep the
  configured log prefix and policy object path derived from the same value.
  Validate a fresh deployment, not only an update to an existing bucket.
- [ ] **Eliminate repeated ECS task-definition changes.** Investigate the
  provider-normalized empty arrays, capability fields, and host port observed
  during the deployment retry. Align configuration with provider behavior
  without ignoring meaningful container changes. Acceptance: a second plan
  after a successful apply has no unexpected changes.
- [ ] **Deliver actionable alerts.** Wire alarm actions to an owned notification
  destination and test delivery and recovery notifications. Add load-balancer
  generated 5xx coverage alongside the existing target 5xx alarm. Confirm metric
  dimensions, missing-data behavior, and thresholds with real traffic.
- [ ] **Separate secrets from ordinary environment values.** Add ECS secret
  references through Secrets Manager or SSM Parameter Store, scoped execution
  role permissions, and optional KMS access. Keep secret payloads out of tfvars,
  task-definition environment values, plans, and logs. Test rotation and the
  task restart required to consume updated values.
- [ ] **Verify rollback and recovery.** Exercise a failed ECS release and confirm
  the service returns to its previous healthy revision. Define frontend rollback
  and state recovery procedures, including recovery time and data-loss targets.
  Verify recovery from versioned state before relying on it.

## Priority 2: availability and security controls

- [ ] **Make availability an explicit workspace choice.** Validate production
  task counts, multi-AZ placement, subnet capacity, and NAT topology. Offer a
  documented lower-cost PoC configuration and a resilient production
  configuration; explain recurring costs before enabling additional resources.
- [ ] **Improve WAF visibility and tuning.** Add configurable WAF logging,
  retention, sensitive-field redaction, managed rule exclusions, and rate limits.
  Test legitimate API requests and frontend traffic before tightening rules.
- [ ] **Tighten network and workload permissions.** Review broad security-group
  egress, add optional VPC endpoints where justified, and expose narrowly scoped
  task-role policies. Verify non-root execution, read-only filesystems, required
  writable mounts, and capability dropping against the actual application.
- [ ] **Protect recovery assets.** Review state access, locking, version
  retention, deletion protection, and break-glass recovery. Separate disposable
  test cleanup settings from production protections and document the effect of
  each destructive option.
- [ ] **Establish account-level controls.** Review the existing configuration
  blueprints for audit logging, threat detection, security findings, budgets,
  and account separation. Record what is enabled and who owns findings;
  deploying an application stack must not imply that account controls exist.
- [ ] **Preserve deployable release artifacts.** Make ECR retention configurable
  and protect images needed by active deployments and rollback procedures.
  Scanning on push should feed a reviewed vulnerability response process.
- [ ] **Define database requirements before adding RDS.** If the application
  needs a database, select availability, encryption, credentials management,
  backup retention, point-in-time recovery, deletion protection, and connection
  limits in the workspace. Prove restoration with a recovery exercise.

## Priority 3: reusable module boundaries and validation

- [ ] **Separate responsibilities in the ALB module.** Move ECS service and
  scaling ownership into a service module and monitoring into a clear module
  boundary. Preserve existing resources with migration guidance and moved
  blocks where applicable; review the plan for unintended replacements.
- [ ] **Expose policy choices as inputs.** Make WAF thresholds, alarm settings,
  autoscaling targets, and retention settings configurable with validation and
  documented defaults. Keep account and environment values in workspace files.
- [ ] **Improve standalone export coverage.** Resolve transitive local module
  dependencies and validate every supported blueprint export. Ensure exports
  contain required modules but exclude credentials, real tfvars, state, plans,
  discovery output, and application clones.
- [ ] **Remove unnecessary identifying example values.** Replace real hosted
  zone IDs and deployment-specific metadata in examples with clear placeholders
  and explain how discovery supplies the corresponding values. Public resource
  identifiers are not credentials, but generic examples are easier to reuse.
- [ ] **Add enforceable repository checks.** There were no checks reported on
  the reviewed main commit. Add Terraform formatting and validation, secret
  scanning, and infrastructure policy checks. Include regression coverage for
  ECR lifecycle rules, ALB log delivery configuration, export completeness, and
  unchanged second plans. Run Terraform workflows through the root Makefile.

## Completion criteria

For each improvement, update module inputs and workspace examples together,
review the complete plan, and verify the relevant behavior in a disposable
environment. Record evidence and remaining limitations. An unchecked item is
proposed work; adding this document does not authorize a deployment, account
permission change, or destructive operation.
