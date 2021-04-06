resource "aws_vpc" "terra_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags = {
    Name = "Terraform VPC"
  }
}

resource "aws_subnet" "public" {
  count             = "${length(var.public_subnets_cidr)}"
  vpc_id            = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${element(var.public_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"

  tags = {
    Name = "public-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count             = "${length(var.private_subnets_cidr)}"
  vpc_id            = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${element(var.private_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"

  tags = {
    Name = "private-${count.index+1}"
  }
}

resource "aws_internet_gateway" "terra_vpc_igw" {
  vpc_id = "${aws_vpc.terra_vpc.id}"

  tags = {
    Name = "Terra VPC Internet Gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terra_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terra_vpc_igw.id}"
  }

  tags = {
    Name = "Public Subnets RT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.terra_vpc.id}"

  tags = {
    Name = "Private Subnets RT"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.public_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count          = "${length(var.private_subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private.*.id,count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public.*.id,0)}"

  tags = {
    Name = "nat"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}
