provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

provider "aws" {
  alias   = "us_east_1"
  profile = var.aws_profile
  region  = "us-east-1"
}
