// EKS Cluster cofigure
resource "aws_eks_cluster" "advent" {
  name     = "${var.service_name}-${var.env}-k8s"
  role_arn = aws_iam_role.eks_assume_role.arn
  vpc_config {
    subnet_ids         = [for subnets in aws_subnet.advent_public : subnets.id]
    security_group_ids = [aws_security_group.advent_eks.id]
  }

  tags = {
    Name    = "${var.service_name}-${var.env}-igw"
    Service = var.service_name
    ENV     = var.env
  }
}

// Security Group configure for EKS Cluster
resource "aws_security_group" "advent_eks" {
  name        = "${var.service_name}-${var.env}-eks"
  description = "${var.service_name} ${var.env} eks security group"
  vpc_id      = aws_vpc.advent_eks.id

  tags = {
    Name    = "${var.service_name}-${var.env}-eks-sg"
    Service = var.service_name
    ENV     = var.env
  }
}

resource "aws_security_group_rule" "advent_eks_local" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.advent_eks.id
  cidr_blocks       = var.own_ip
}

resource "aws_security_group_rule" "advent_eks_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.advent_eks.id
  source_security_group_id = aws_security_group.k8s_node.id
}

resource "aws_security_group_rule" "eks_2node_ingress_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.advent_eks.id
  source_security_group_id = aws_security_group.k8s_node.id
}

resource "aws_security_group_rule" "eks_default_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.advent_eks.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_2node_egress" {
  type                     = "egress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.advent_eks.id
  source_security_group_id = aws_security_group.k8s_node.id
}

resource "aws_security_group_rule" "eks_2node_egress_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.advent_eks.id
  source_security_group_id = aws_security_group.k8s_node.id
}
