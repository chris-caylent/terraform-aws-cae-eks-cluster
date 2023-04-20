# ---------------------------------------------------------------------------------------------------------------------
# CLUSTER KMS KEY
# ---------------------------------------------------------------------------------------------------------------------

# Create a KMS customer managed key
resource "aws_kms_key" "test_kms_key" {
  description             = "Terratest KMS key"
  policy                  = data.aws_iam_policy_document.eks_kms_key_policy.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

# Assign an alias to the key
resource "aws_kms_alias" "this" {
  name          = "alias/test-eks-cluster-kms"
  target_key_id = aws_kms_key.test_kms_key.key_id
}


module "eks_core" {
  source = "../../"

  create = var.create_eks

  cluster_name     = local.cluster_name
  cluster_version  = "1.23"
  cluster_timeouts = var.cluster_timeouts

  # IAM Role
  create_iam_role = var.create_iam_role
  iam_role_arn    = var.iam_role_arn

  iam_role_use_name_prefix      = false
  iam_role_name                 = local.cluster_iam_role_name
  iam_role_path                 = var.iam_role_path
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  iam_role_additional_policies  = var.iam_role_additional_policies

  # EKS Cluster VPC Config
  subnet_ids                           = module.vpc.private_subnets
  control_plane_subnet_ids             = var.control_plane_subnet_ids
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Kubernetes Network Config
  cluster_ip_family         = var.cluster_ip_family
  cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr

  # Cluster Security Group
  create_cluster_security_group           = var.create_cluster_security_group
  cluster_security_group_id               = var.cluster_security_group_id
  vpc_id                                  = module.vpc.vpc_id
  cluster_additional_security_group_ids   = var.cluster_additional_security_group_ids
  cluster_security_group_additional_rules = var.cluster_security_group_additional_rules
  cluster_security_group_tags             = var.cluster_security_group_tags

  # Worker Node Security Group
  create_node_security_group           = var.create_node_security_group
  node_security_group_additional_rules = var.node_security_group_additional_rules
  node_security_group_tags             = var.node_security_group_tags

  # IRSA
  enable_irsa              = var.enable_irsa
  openid_connect_audiences = var.openid_connect_audiences
  custom_oidc_thumbprints  = var.custom_oidc_thumbprints

  # TAGS
  tags = var.tags

  # CLUSTER LOGGING
  create_cloudwatch_log_group            = var.create_cloudwatch_log_group
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id

  # CLUSTER ENCRYPTION
  attach_cluster_encryption_policy = false
  kms_key_arn                      = aws_kms_key.test_kms_key.arn
  cluster_encryption_config = length(var.cluster_encryption_config) == 0 ? [
    {
      provider_key_arn = try(aws_kms_key.test_kms_key.arn, var.cluster_kms_key_arn)
      resources        = ["secrets"]
    }
  ] : var.cluster_encryption_config

  cluster_identity_providers = var.cluster_identity_providers

}

################################################################################
# Supporting resources -- VPC
################################################################################



module "vpc" {
  source = "" #insert remote git link here

  name        = local.name
  contact     = var.contact
  environment = var.environment
  team        = var.team
  purpose     = var.purpose
  cidr        = local.vpc_cidr

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "default-net-acl" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "default-rt" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "default-sg" }


  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = var.tags
}
