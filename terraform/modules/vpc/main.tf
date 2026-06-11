# -----------------------------------------------------------------------------
# MODULE: vpc
# Creates VPC, public/private subnets, IGW, NAT Gateway, route tables,
# and security groups required for Databricks E2 deployment on AWS.
# -----------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# ─── VPC ────────────────────────────────────────────────────────────────────

resource "aws_vpc" "client-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# ─── INTERNET GATEWAY ───────────────────────────────────────────────────────

resource "aws_internet_gateway" "client-igw" {
  vpc_id = aws.vpc.client-vpc.id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# ─── PUBLIC SUBNETS ─────────────────────────────────────────────────────────

resource "aws_subnet" "client-public-subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.client-vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Tier = "Public"
  })
}

# ─── PRIVATE SUBNETS (Databricks nodes live here) ───────────────────────────

resource "aws_subnet" "client-private-subnet" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.client-vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Tier = "Private"
  })
}

# ─── ELASTIC IPs FOR NAT GATEWAYS ───────────────────────────────────────────

resource "aws_eip" "client-nat-eip" {
  count  = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.client-igw]
}

# ─── NAT GATEWAYS ───────────────────────────────────────────────────────────

resource "aws_nat_gateway" "client-nat-gateway" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  allocation_id = aws_eip.client-nat-eip[count.index].id
  subnet_id     = aws_subnet.client-public-subnet[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.client-igw]
}

# ─── PUBLIC ROUTE TABLE ─────────────────────────────────────────────────────

resource "aws_route_table" "client-public-rt" {
  vpc_id = aws_vpc.client-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.client-igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "client-public-rt-association" {
  count          = length(aws_subnet.client-public-subnet)
  subnet_id      = aws_subnet.client-public-subnet[count.index].id
  route_table_id = aws_route_table.client-public-rt.id
}

# ─── PRIVATE ROUTE TABLES ───────────────────────────────────────────────────

resource "aws_route_table" "client-private-rt" {
  count  = var.single_nat_gateway ? 1 : length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.client-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.client-nat-gateway[0].id : aws_nat_gateway.client-nat-gateway[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "name" {
  count          = length(aws_subnet.client-public-subnet)
  subnet_id      = aws_subnet.client-private-subnet[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.client-private-rt[0].id : aws_route_table.client-private-rt[count.index].id
}

# ─── DATABRICKS SECURITY GROUP ──────────────────────────────────────────────
# Databricks requires all nodes to communicate on all ports within the group.

resource "aws_security_group" "databricks-sg" {
  name        = "${var.name_prefix}-databricks-sg"
  description = "Security group for Databricks cluster nodes"
  vpc_id      = aws_vpc.client-vpc.id

  ingress {
    description = "Allow all inbound traffic within the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-databricks-sg"
  })
}

# ─── VPC ENDPOINTS (optional but recommended for cost/security) ──────────────
# VPC endpoints allow private connectivity to AWS services without traversing the internet.

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.client-vpc.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat(aws_route_table.client-public-rt[*].id, aws_route_table.client-private-rt[*].id)

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "sts" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id              = aws_vpc.client-vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.client-private-subnet[*].id
  security_group_ids  = [aws_security_group.databricks-sg.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-sts-endpoint"
  })
}
