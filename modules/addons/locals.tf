locals {

  eks_oidc_issuer_url  = var.eks_oidc_provider != null ? var.eks_oidc_provider : replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_endpoint = var.eks_cluster_endpoint != null ? var.eks_cluster_endpoint : data.aws_eks_cluster.eks_cluster.endpoint
  eks_cluster_version  = var.eks_cluster_version != null ? var.eks_cluster_version : data.aws_eks_cluster.eks_cluster.version

  # Configuration for managing add-ons via ArgoCD.
  argocd_addon_config = {
    #argoRollouts              = var.enable_argo_rollouts ? module.argo_rollouts[0].argocd_gitops_config : null
    awsCloudWatchMetrics      = var.enable_aws_cloudwatch_metrics ? module.aws_cloudwatch_metrics[0].argocd_gitops_config : null
    awsLoadBalancerController = var.enable_aws_load_balancer_controller ? module.aws_load_balancer_controller[0].argocd_gitops_config : null
    certManager               = var.enable_cert_manager ? module.cert_manager[0].argocd_gitops_config : null
    #clusterAutoscaler         = var.enable_cluster_autoscaler ? module.cluster_autoscaler[0].argocd_gitops_config : null
    corednsAutoscaler = var.enable_amazon_eks_coredns && var.enable_coredns_autoscaler && length(var.coredns_autoscaler_helm_config) > 0 ? module.coredns_autoscaler[0].argocd_gitops_config : null
    #ingressNginx              = var.enable_ingress_nginx ? module.ingress_nginx[0].argocd_gitops_config : null
    #metricsServer             = var.enable_metrics_server ? module.metrics_server[0].argocd_gitops_config : null
    #karpenter                 = var.enable_karpenter ? module.karpenter[0].argocd_gitops_config : null
  }

  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = local.eks_cluster_endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.name
    eks_cluster_id                 = var.eks_cluster_id
    eks_oidc_issuer_url            = local.eks_oidc_issuer_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
    tags                           = var.tags
    irsa_iam_role_path             = var.irsa_iam_role_path
    irsa_iam_permissions_boundary  = var.irsa_iam_permissions_boundary
  }

  # For addons that pull images from a region-specific ECR container registry by default
  # for more information see: https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  amazon_container_image_registry_uris = merge(
    {
      eu-central-1 = "602401143452.dkr.ecr.eu-central-1.amazonaws.com",
      us-west-2    = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
    },
    var.custom_image_registry_uri
  )
}
