locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.k8s_node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "eks_endpoint" {
  value = aws_eks_cluster.advent.endpoint
}

output "eks_role" {
  value = aws_iam_role.eks_assume_role.arn
}

output "k8s_node_role" {
  value = aws_iam_role.k8s_node.arn
}
