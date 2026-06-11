# =============================================================================
# ENVIRONMENT: dev
# Calls all modules in order to build the full Databricks stack from scratch.
# =============================================================================

locals {
  env         = "dev"
  name_prefix = "${var.project_name}-${local.env}"
  aws_region  = var.aws_region

  common_tags = {
    Project     = var.project_name
    Environment = local.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}


# ─── VPC ─────────────────────────────────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = local.name_prefix
  aws_region           = local.aws_region
  tags                 = local.common_tags
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
  single_nat_gateway   = true
  enable_vpc_endpoints = true
}
