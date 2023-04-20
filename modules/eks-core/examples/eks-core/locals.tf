locals {
  cluster_iam_role_name = var.iam_role_name == null ? "${var.cluster_name}-cluster-role" : var.iam_role_name
  cluster_iam_role_arn  = var.create_iam_role ? "arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_iam_role_name}" : var.iam_role_arn

  name = basename(path.cwd)
  # var.cluster_name is used in the Terratest
  cluster_name = coalesce(var.cluster_name, local.name)
  region       = var.region

  vpc_cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}