# Terraform state configuration blueprint

Creates a versioned, encrypted, private S3 bucket for Terraform state. Use
separate keys per application and environment, with S3 native lock files:

```hcl
terraform {
  backend "s3" {
    bucket       = "OUTPUT_BUCKET_NAME"
    key          = "template-monorepo/production/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}
```
