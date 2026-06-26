# Create a VPC
resource "aws_vpc" "vpc-1" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = false

  tags = var.common_tags
}

# Create a VPC Flow Log
resource "aws_flow_log" "vpc_flow_logs" {
  vpc_id               = aws_vpc.vpc-1.id
  log_destination      = var.s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
}

# Create public subnet 1
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = aws_vpc.vpc-1.id
  availability_zone = "${var.region}a"

  tags = var.common_tags
}

# Create public subnet 2
resource "aws_subnet" "public-subnet-2" {
  cidr_block        = var.public_subnet_2_cidr
  vpc_id            = aws_vpc.vpc-1.id
  availability_zone = "${var.region}b"

  tags = var.common_tags
}

# Create private subnet 1
resource "aws_subnet" "private-subnet-1" {
  cidr_block        = var.private_subnet_1_cidr
  vpc_id            = aws_vpc.vpc-1.id
  availability_zone = "${var.region}a"

  tags = var.common_tags
}

# Create private subnet 2
resource "aws_subnet" "private-subnet-2" {
  cidr_block        = var.private_subnet_2_cidr
  vpc_id            = aws_vpc.vpc-1.id
  availability_zone = "${var.region}b"

  tags = var.common_tags
}

# Create a public route table
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc-1.id
  tags   = var.common_tags
}

# Create a private route table
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc-1.id
  tags   = var.common_tags
}

# Associate public subnet 1 with the public route table
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-1.id
}

# Associate public subnet 2 with the public route table
resource "aws_route_table_association" "public-route-2-association" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-2.id
}

# Associate private subnet 1 with the private route table
resource "aws_route_table_association" "private-route-1-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-1.id
}

# Associate private subnet 2 with the private route table
resource "aws_route_table_association" "private-route-2-association" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-2.id
}

# Create a NAT Gateway in public subnet 1
#resource "aws_nat_gateway" "nat-gw" {
#  allocation_id = aws_eip.nat-gw-eip.id
#  subnet_id     = aws_subnet.public-subnet-1.id

#  tags = var.common_tags

#  depends_on = [
#  ]
#    aws_eip.nat-gw-eip
#}

resource "aws_eip" "nat-gw-eip" {
  domain = "vpc"

  tags = var.common_tags
}

# Create a NAT Gateway in public subnet 1
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-gw-eip.id
  subnet_id     = aws_subnet.public-subnet-1.id

  tags = var.common_tags
}

# Create a route in the private route table to route traffic through the NAT Gateway
resource "aws_route" "nat-gw-route" {
  route_table_id         = aws_route_table.private-route-table.id
  nat_gateway_id         = aws_nat_gateway.nat-gw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc-1.id
  tags   = var.common_tags
}

# Create a route in the public route table to route traffic through the Internet Gateway
resource "aws_route" "public-internet-igw-route" {
  route_table_id         = aws_route_table.public-route-table.id
  gateway_id             = aws_internet_gateway.internet-gateway.id
  destination_cidr_block = "0.0.0.0/0"
}
