# ECS application blueprint

This blueprint deploys a testable containerized application on ECS Fargate:

- private application subnets behind a public Application Load Balancer;
- ECR with immutable image tags and scan-on-push;
- CloudWatch container logs and ECS Container Insights;
- optional ACM and Route 53 DNS for `api.template-monorepo.judigot.com`;
- optional S3/CloudFront is intentionally deferred until the frontend build and
  bucket deployment pipeline are defined.

The defaults run a public nginx Alpine image as an HTTP-only smoke test; this
does not deploy template-monorepo. The health check requires wget in the image.
For an application deployment, build and publish the API image first, then set
its digest-pinned reference, container port, and health path. Terraform does not
build or publish images. Set both domain_name and route53_zone_id to enable TLS;
HTTP then redirects to HTTPS. Give each environment a distinct api_subdomain.

Copy the export into a durable application checkout before initializing Terraform.
Configure isolated remote state for each environment (dedicated HCP workspaces
or separate backend keys); changing a var-file alone does not isolate state.
The exporter refuses to overwrite initialized exports and operator tfvars.

CPU target tracking scales between desired_count (the minimum) and max_capacity.
The smoke-test default caps this at one task. Terraform leaves the live desired
count to autoscaling after initial creation. Health alarms are created; configure
alarm_actions with notification topic ARNs to receive alerts. Untagged ECR images
expire after seven days; tagged images are retained for rollback and need a
separate release-retention policy. NAT, ALB, tasks, and logs incur ongoing charges.

This is a disposable test blueprint, not a complete production baseline yet.
Before production use, add per-AZ egress, appropriate edge protection, alarm
notifications, deployment identity, remote state locking, and a tested rollback
path. Complete application and frontend delivery and validate with Terraform. Do not use
an EC2 init script for application setup; container images and explicit ECS
deployment tasks are the repeatable bootstrap boundary.
