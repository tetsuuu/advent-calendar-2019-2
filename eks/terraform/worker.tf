// EKS Node cofigure
data "aws_ami" "k8s_node" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.advent.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

data "aws_region" "current" {}

locals {
  k8s_node_userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.advent.endpoint}' --b64-cluster-ca '${aws_eks_cluster.advent.certificate_authority[0].data}' '${aws_eks_cluster.advent.name}'
USERDATA
}

resource "aws_iam_instance_profile" "k8s_node" {
  name = "${var.service_name}-${var.env}-k8s-node-profile"
  role = aws_iam_role.k8s_node.name
}

resource "aws_launch_configuration" "k8s_node" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k8s_node.name
  image_id                    = data.aws_ami.k8s_node.id
  instance_type               = "t2.small"
  key_name                    = var.my_key
  name_prefix                 = "${var.service_name}-${var.env}-k8s-node"
  security_groups             = [aws_security_group.k8s_node.id]
  user_data_base64            = base64encode(local.k8s_node_userdata)

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "k8s_node" {
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.k8s_node.id
  max_size             = 3
  min_size             = 1
  name                 = "${var.service_name}-${var.env}-k8s-autoscaling"
  vpc_zone_identifier  = [for subnets in aws_subnet.advent_public : subnets.id]

  tag {
    key                 = "ENV"
    value               = var.env
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = var.service_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${var.service_name}-${var.env}-k8s-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.advent.name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

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
