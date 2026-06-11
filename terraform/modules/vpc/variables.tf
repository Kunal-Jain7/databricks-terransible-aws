variable "name_prefix" {
  description = "Prefix for all resources names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR Block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper for dev; use false for HA in prod)"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create S3 and STS VPC endpoints (required for Databricks on AWS)"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "Region where all the resources are being created"
  type        = string
  default     = "us-west-1"
}

variable "tags" {
  description = "Common tags for all the resources"
  type        = map(string)
  default     = {}
}
