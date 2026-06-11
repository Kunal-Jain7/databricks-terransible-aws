variable "project_name" {
  description = "Short Name for the project"
  type        = string
  default     = "dbks"
}

variable "aws_region" {
  description = "AWS Region to deploy resources in"
  type        = string
  default     = "us-west-1"
}

variable "owner" {
  description = "Team or individual owning these resources (for tagging)"
  type        = string
  default     = "data-platform-team"
}

