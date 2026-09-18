# ECS application blueprint

This blueprint deploys a testable containerized application on ECS Fargate:

- private application subnets behind a public Application Load Balancer;
- ECR with immutable image tags and scan-on-push;
- CloudWatch container logs and ECS Container Insights;
- optional ACM and Route 53 DNS for `api.template-monorepo.judigot.com`;
- private S3 frontend storage behind CloudFront Origin Access Control;
- a `us-east-1` ACM certificate and Route 53 A/AAAA aliases for the frontend;
- security response headers, compressed caching, and SPA route fallback.
- WAF managed common rules and IP rate limits at both CloudFront and the ALB;
- VPC flow logs, ALB access logs, and ECS/ALB CloudWatch alarms;
- lifecycle retention for access logs, state history, and tagged ECR releases.

The defaults run a public nginx Alpine image as an HTTP-only smoke test; this
does not deploy template-monorepo. The health check requires wget in the image.
For an application deployment, build and publish the API image first, then set
its digest-pinned reference, container port, and health path. Terraform does not
build or publish application artifacts. Set both domain_name and route53_zone_id to enable TLS;
HTTP then redirects to HTTPS. Give each environment a distinct api_subdomain.
Set `frontend_domain_name` to the Route 53 apex or a dedicated environment
hostname. The workspace apply script builds and publishes the Vite bundle after
Terraform provisions its private bucket and CloudFront distribution.

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

The hardening defaults are designed for a small production deployment while
retaining the explicit `production_mode` switch: production uses one NAT
gateway per AZ and protects deletion, while disposable environments can still
use a single NAT gateway and controlled teardown.

Validate application and frontend delivery with Terraform. Do not use
an EC2 init script for application setup; container images and explicit ECS
deployment tasks are the repeatable bootstrap boundary.
