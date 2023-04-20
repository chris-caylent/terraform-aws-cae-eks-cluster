#-----------------AWS Managed EKS Add-ons----------------------

module "aws_vpc_cni" {
  source = "./vpc-cni"

  count = var.enable_amazon_eks_vpc_cni ? 1 : 0

  enable_ipv6 = var.enable_ipv6
  addon_config = merge(
    {
      kubernetes_version = local.eks_cluster_version
    },
    var.amazon_eks_vpc_cni_config,
  )

  addon_context = local.addon_context
}

module "aws_coredns" {
  source = "./coredns"

  count = var.enable_amazon_eks_coredns ? 1 : 0

  addon_context = local.addon_context

  # Amazon EKS CoreDNS addon
  enable_amazon_eks_coredns = var.enable_amazon_eks_coredns
  addon_config = merge(
    {
      kubernetes_version = local.eks_cluster_version
    },
    var.amazon_eks_coredns_config,
  )

  # CoreDNS cluster proportioanl autoscaler
  enable_cluster_proportional_autoscaler      = var.enable_coredns_cluster_proportional_autoscaler
  cluster_proportional_autoscaler_helm_config = var.coredns_cluster_proportional_autoscaler_helm_config

  remove_default_coredns_deployment      = var.remove_default_coredns_deployment
  eks_cluster_certificate_authority_data = data.aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

module "aws_kube_proxy" {
  source = "./kube-proxy"

  count = var.enable_amazon_eks_kube_proxy ? 1 : 0

  addon_config = merge(
    {
      kubernetes_version = local.eks_cluster_version
    },
    var.amazon_eks_kube_proxy_config,
  )

  addon_context = local.addon_context
}

# module "aws_ebs_csi_driver" {
#   source = "./aws-ebs-csi-driver"

#   count = var.enable_amazon_eks_aws_ebs_csi_driver || var.enable_self_managed_aws_ebs_csi_driver ? 1 : 0

#   # Amazon EKS aws-ebs-csi-driver addon
#   enable_amazon_eks_aws_ebs_csi_driver = var.enable_amazon_eks_aws_ebs_csi_driver
#   addon_config = merge(
#     {
#       kubernetes_version = local.eks_cluster_version
#     },
#     var.amazon_eks_aws_ebs_csi_driver_config,
#   )

#   addon_context = local.addon_context
# }

module "csi_secrets_store_provider_aws" {
  count             = var.enable_secrets_store_csi_driver_provider_aws ? 1 : 0
  source            = "./csi-secrets-store-provider-aws"
  helm_config       = var.csi_secrets_store_provider_aws_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "secrets_store_csi_driver" {
  count             = var.enable_secrets_store_csi_driver ? 1 : 0
  source            = "./secrets-store-csi-driver"
  helm_config       = var.secrets_store_csi_driver_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

#-----------------Kubernetes Add-ons----------------------

module "argocd" {
  count         = var.enable_argocd ? 1 : 0
  source        = "./argocd"
  helm_config   = var.argocd_helm_config
  applications  = var.argocd_applications
  addon_config  = { for k, v in local.argocd_addon_config : k => v if v != null }
  addon_context = local.addon_context
}

# module "argo_rollouts" {
#   count             = var.enable_argo_rollouts ? 1 : 0
#   source            = "./argo-rollouts"
#   helm_config       = var.argo_rollouts_helm_config
#   manage_via_gitops = var.argocd_manage_add_ons
#   addon_context     = local.addon_context
# }

module "aws_cloudwatch_metrics" {
  count             = var.enable_aws_cloudwatch_metrics ? 1 : 0
  source            = "./cloudwatch-metrics"
  helm_config       = var.aws_cloudwatch_metrics_helm_config
  irsa_policies     = var.aws_cloudwatch_metrics_irsa_policies
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "aws_load_balancer_controller" {
  count             = var.enable_aws_load_balancer_controller ? 1 : 0
  source            = "./aws-load-balancer-controller"
  helm_config       = var.aws_load_balancer_controller_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
}

# module "cluster_autoscaler" {
#   source = "./cluster-autoscaler"

#   count = var.enable_cluster_autoscaler ? 1 : 0

#   eks_cluster_version = local.eks_cluster_version
#   helm_config         = var.cluster_autoscaler_helm_config
#   manage_via_gitops   = var.argocd_manage_add_ons
#   addon_context       = local.addon_context
# }

module "coredns_autoscaler" {
  count             = var.enable_amazon_eks_coredns && var.enable_coredns_autoscaler && length(var.coredns_autoscaler_helm_config) > 0 ? 1 : 0
  source            = "./cluster-proportional-autoscaler"
  helm_config       = var.coredns_autoscaler_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

# module "ingress_nginx" {
#   count             = var.enable_ingress_nginx ? 1 : 0
#   source            = "./ingress-nginx"
#   helm_config       = var.ingress_nginx_helm_config
#   manage_via_gitops = var.argocd_manage_add_ons
#   addon_context     = local.addon_context
# }

# module "karpenter" {
#   count                     = var.enable_karpenter ? 1 : 0
#   source                    = "./karpenter"
#   helm_config               = var.karpenter_helm_config
#   irsa_policies             = var.karpenter_irsa_policies
#   node_iam_instance_profile = var.karpenter_node_iam_instance_profile
#   manage_via_gitops         = var.argocd_manage_add_ons
#   addon_context             = local.addon_context
# }

# module "kubernetes_dashboard" {
#   count             = var.enable_kubernetes_dashboard ? 1 : 0
#   source            = "./kubernetes-dashboard"
#   helm_config       = var.kubernetes_dashboard_helm_config
#   manage_via_gitops = var.argocd_manage_add_ons
#   addon_context     = local.addon_context
# }

module "metrics_server" {
  count             = var.enable_metrics_server ? 1 : 0
  source            = "./metrics-server"
  helm_config       = var.metrics_server_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "datadog_agent" {
  count             = var.enable_datadog_agent ? 1 : 0
  source            = "./datadog"
  helm_config       = var.datadog_agent_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "splunk" {
  count             = var.enable_splunk_logging ? 1 : 0
  source            = "./splunk"
  helm_config       = var.splunk_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "cert_manager" {
  count                             = var.enable_cert_manager ? 1 : 0
  source                            = "./cert-manager"
  helm_config                       = var.cert_manager_helm_config
  manage_via_gitops                 = var.argocd_manage_add_ons
  irsa_policies                     = var.cert_manager_irsa_policies
  addon_context                     = local.addon_context
  domain_names                      = var.cert_manager_domain_names
  install_letsencrypt_issuers       = var.cert_manager_install_letsencrypt_issuers
  letsencrypt_email                 = var.cert_manager_letsencrypt_email
  kubernetes_svc_image_pull_secrets = var.cert_manager_kubernetes_svc_image_pull_secrets
}

module "cert_manager_csi_driver" {
  count             = var.enable_cert_manager_csi_driver ? 1 : 0
  source            = "./cert-manager-csi-driver"
  helm_config       = var.cert_manager_csi_driver_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "aws_privateca_issuer" {
  count                   = var.enable_aws_privateca_issuer ? 1 : 0
  source                  = "./aws-privateca-issuer"
  helm_config             = var.aws_privateca_issuer_helm_config
  manage_via_gitops       = var.argocd_manage_add_ons
  addon_context           = local.addon_context
  aws_privateca_acmca_arn = var.aws_privateca_acmca_arn
  irsa_policies           = var.aws_privateca_issuer_irsa_policies
}