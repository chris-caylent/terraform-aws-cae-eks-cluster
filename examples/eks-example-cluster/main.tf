provider "aws" {
  region = local.region
}

provider "kubernetes" {
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks_cluster.eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.eks_cluster_id
}

data "aws_availability_zones" "available" {
  filter {
    name   = "region-name"
    values = [var.region]
  }
}

locals {
  name = basename(path.cwd)
  # var.cluster_name is for Terratest
  cluster_name = coalesce(var.cluster_name, local.name)
  region       = var.region

  vpc_cidr = "10.0.0.0/16"

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    "purpose"     = var.purpose
    "team"        = var.team
    "environment" = var.environment
    "contact"     = var.contact
  }
}

################################################################################
# EKS Core
################################################################################


module "eks_cluster" {
  source = "../../"

  cluster_name    = local.cluster_name
  cluster_version = "1.23"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ng"
      instance_types  = ["m5.large"]
      min_size        = 2
      max_size        = 4
      desired_size    = 2
      subnet_ids      = module.vpc.private_subnets
    }
  }

  tags = local.tags
}

module "addons" {
  source = "../../modules/addons"

  eks_cluster_id       = module.eks_cluster.eks_cluster_id
  eks_cluster_endpoint = module.eks_cluster.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_cluster.oidc_provider
  eks_cluster_version  = module.eks_cluster.eks_cluster_version

  # enable the argocd addon
  enable_argocd = true
  argocd_applications = {
    workload_app_1 = var.workload
  }

  argocd_helm_config = {
    values = [templatefile("${path.module}/helm-values/argocd/${var.argocd_values}", {
      argocd_cert_arn = jsonencode(var.argocd_cert_arn)
    })]
  }

  # let argo cd manage the addons
  argocd_manage_add_ons = false

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni           = true
  enable_amazon_eks_coredns           = true
  enable_amazon_eks_kube_proxy        = true
  enable_aws_load_balancer_controller = true
  enable_aws_cloudwatch_metrics       = true

  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true

  enable_cert_manager        = false
  cert_manager_irsa_policies = [aws_iam_policy.cert-manager-cross-account.arn]


  tags = local.tags
}

# ---------------------------------------------------------------
# Creating IAM Role for Service Account
# ---------------------------------------------------------------

resource "aws_iam_policy" "secrets_management_policy" {
  description = "IAM policy for secrets management"
  name        = "${module.eks_cluster.eks_cluster_id}-${local.application}-irsa"
  policy      = data.aws_iam_policy_document.secrets_management_ro_policy.json
}

module "iam_role_service_account" {
  for_each = var.service_accounts

  source = "../../modules/irsa"

  eks_cluster_id        = module.eks_cluster.eks_cluster_id
  eks_oidc_provider_arn = module.eks_cluster.eks_oidc_provider_arn

  create_kubernetes_namespace = each.value["create_namespace"] #this must be false if you are applying an applicaiton add-on, otherwise an error will occur at apply that ns already exists
  kubernetes_namespace        = each.value["namespace"]
  kubernetes_service_account  = each.key
  irsa_iam_role_name          = each.key
  irsa_iam_policies           = [aws_iam_policy.secrets_management_policy.arn]

  depends_on = [module.eks_cluster]
}

################################################################################
# Supporting resources -- VPC
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  name        = local.name
  contact     = var.contact
  environment = var.environment
  team        = var.team
  purpose     = var.purpose

  cidr = "10.0.0.0/16"

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.cluster_name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.cluster_name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.cluster_name}-default" }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }

  tags = local.tags
}

resource "aws_security_group" "vpc_tls" {
  name_prefix = "${local.name}-vpc_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = local.tags
}
