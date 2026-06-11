output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.client-vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.client-vpc.cidr_block
}

output "public_subnet_ids" {
  description = "ID's of the public subnet"
  value       = aws_subnet.client-public-subnet[*].id
}

output "private_subnet_ids" {
  description = "ID's of the private subnet"
  value       = aws_subnet.client-private-subnet[*].id
}

output "databricks_security_id" {
  description = "Security Group ID of the Databricks Cluster Nodes"
  value       = aws_security_group.databricks-sg.id
}

output "nat_gateway_ids" {
  description = "ID's of the NAT Gateway"
  value       = aws_nat_gateway.client-nat-gateway[*].id
}

