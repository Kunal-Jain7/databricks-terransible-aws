# =============================================================================
# PROVIDERS — dev environment
# Two Databricks provider configurations are needed:
#   1. databricks.mws  — account-level (creates workspace)
#   2. databricks.workspace — workspace-level (creates cluster, policies, etc.)
# =============================================================================

terraform {
  required_version = ">= 1.15.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "databricks-terraform-state-622385388668"
    key    = "databricks/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "dev"
    }
  }
}
