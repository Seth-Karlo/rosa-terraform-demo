# Create VPC

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Create subnets

resource "aws_subnet" "public" {
  count      = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.cluster_name} Public Subnet ${count.index}"
  }
}

resource "aws_subnet" "private" {
  count      = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index+3}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.cluster_name} Private Subnet ${count.index}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# EIP for NAT Gateways
resource "aws_eip" "nat" {
  count    = 3
}

# NAT Gateways
resource "aws_nat_gateway" "nat" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.cluster_name} NAT GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public_to_igw" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name} route table public to igw"
  }
}

resource "aws_route_table" "private_to_natgw" {
  count = 3
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${var.cluster_name} route table private to natgw ${count.index}"
  }
}

# Subnet associations
resource "aws_route_table_association" "private_to_natgw" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_to_natgw[count.index].id
}

resource "aws_route_table_association" "public_to_igw" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_to_igw.id
}
