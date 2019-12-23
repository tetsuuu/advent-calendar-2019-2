resource "aws_vpc" "advent_eks" {
  cidr_block = var.cidr_block

  tags = {
    Name                                        = "${var.service_name}-${var.env}-vpc"
    Service                                     = var.service_name
    ENV                                         = var.env
    "kubernetes.io/cluster/advent-k8s-sand-k8s" = "shared"
  }
}

resource "aws_subnet" "advent_public" {
  for_each                = var.availability_zone
  cidr_block              = cidrsubnet(aws_vpc.advent_eks.cidr_block, 2, each.value)
  vpc_id                  = aws_vpc.advent_eks.id
  availability_zone       = each.key
  map_public_ip_on_launch = true


  tags = {
    Name                                        = "${var.service_name}-${var.env}-public-${each.key}"
    Service                                     = var.service_name
    ENV                                         = var.env
    "kubernetes.io/cluster/advent-k8s-sand-k8s" = "shared"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.advent_eks.id

  tags = {
    Name    = "${var.service_name}-${var.env}-igw"
    Service = var.service_name
    ENV     = var.env
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.advent_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name    = "${var.service_name}-${var.env}-route"
    Service = var.service_name
    ENV     = var.env
  }
}

resource "aws_route_table_association" "public" {
  for_each       = var.availability_zone
  route_table_id = aws_route_table.default.id
  subnet_id      = aws_subnet.advent_public[each.key].id
}
