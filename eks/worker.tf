// EKS Node cofigure
resource "aws_eks_node_group" "k8s_node" {
  cluster_name    = aws_eks_cluster.advent.name
  node_group_name = "advent-k8s"
  node_role_arn   = aws_iam_role.k8s_node.arn
  subnet_ids      = [for subnets in aws_subnet.advent_public : subnets.id]

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  disk_size = 20
  instance_types = ["t2.small"]


  depends_on = [
    aws_iam_role_policy_attachment.managed_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.managed_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.managed_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name    = "${var.service_name}-${var.env}-k8s-node"
    Service = var.service_name
    ENV     = var.env
  }
}

// Security Group configure for EKS Node
resource "aws_security_group" "k8s_node" {
  name        = "${var.service_name}-${var.env}-k8s-node"
  description = "${var.service_name} ${var.env} k8s node security group"
  vpc_id      = aws_vpc.advent_eks.id

  tags = {
    Name    = "${var.service_name}-${var.env}-k8s-node-sg"
    Service = var.service_name
    ENV     = var.env
  }
}

resource "aws_security_group_rule" "k8s_node_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k8s_node.id
}

resource "aws_security_group_rule" "control_plane_ingress" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_node.id
  source_security_group_id = aws_security_group.advent_eks.id
}

resource "aws_security_group_rule" "control_plane_ingress_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k8s_node.id
  source_security_group_id = aws_security_group.advent_eks.id
}

resource "aws_security_group_rule" "k8s_node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_node.id
}
