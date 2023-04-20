################################################################################
# NAMING AND TAGGING
################################################################################

variable "region" {
  type        = string
  description = "The default region for the test."
  default     = "us-west-2"
}

variable "contact" {
  type        = string
  description = "The contact for tagging"
  default     = "cae-team@caylent.com"
}

variable "environment" {
  type        = string
  description = "The environment for the text (sbx, dev, qa, etc)"
  default     = "sbx"
}

variable "team" {
  type        = string
  description = "The team, used for tagging."
  default     = "caylent-team"
}

variable "purpose" {
  type        = string
  description = "The purpose of this resource, used for tagging"
  default     = "terratest"
}

variable "tags" {
  type        = map(any)
  description = "Resource tags"
  default     = {}
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
  default     = ""
}

variable "eks_cluster_id" {
  type        = string
  description = "EKS Cluster Id"
  default     = ""
}

variable "eks_cluster_domain" {
  type        = string
  description = "The domain for the EKS cluster"
  default     = ""
}

variable "eks_worker_security_group_id" {
  type        = string
  description = "EKS Worker Security group Id created by EKS module"
  default     = ""
}

variable "data_plane_wait_arn" {
  type        = string
  description = "Addon deployment will not proceed until this value is known. Set to node group/Fargate profile ARN to wait for data plane to be ready before provisioning addons"
  default     = ""
}

variable "auto_scaling_group_names" {
  type        = list(string)
  description = "List of self-managed node groups autoscaling group names"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
  default     = {}
}

variable "irsa_iam_role_path" {
  type        = string
  description = "IAM role path for IRSA roles"
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  type        = string
  description = "IAM permissions boundary for IRSA roles"
  default     = ""
}

variable "eks_oidc_provider" {
  type        = string
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  default     = null
}

variable "eks_cluster_endpoint" {
  type        = string
  description = "Endpoint for your Kubernetes API server"
  default     = null
}

variable "eks_cluster_version" {
  type        = string
  description = "The Kubernetes version for the cluster"
  default     = null
}

#-----------EKS MANAGED ADD-ONS------------
variable "enable_ipv6" {
  type        = bool
  description = "Enable Ipv6 network. Attaches new VPC CNI policy to the IRSA role"
  default     = false
}

variable "amazon_eks_vpc_cni_config" {
  type        = any
  description = "ConfigMap of Amazon EKS VPC CNI add-on"
  default     = {}
}

variable "enable_amazon_eks_coredns" {
  type        = bool
  description = "Enable Amazon EKS CoreDNS add-on"
  default     = false
}

variable "amazon_eks_coredns_config" {
  type        = any
  description = "Configuration for Amazon CoreDNS EKS add-on"
  default     = {}
}

variable "remove_default_coredns_deployment" {
  type        = bool
  description = "Determines whether the default deployment of CoreDNS is removed and ownership of kube-dns passed to Helm"
  default     = false
}

variable "enable_coredns_cluster_proportional_autoscaler" {
  type        = bool
  description = "Enable cluster-proportional-autoscaler for CoreDNS"
  default     = true
}

variable "coredns_cluster_proportional_autoscaler_helm_config" {
  default     = {}
  description = "Helm provider config for the CoreDNS cluster-proportional-autoscaler"
  type        = any
}

variable "amazon_eks_kube_proxy_config" {
  type        = any
  description = "ConfigMap for Amazon EKS Kube-Proxy add-on"
  default     = {}
}

variable "amazon_eks_aws_ebs_csi_driver_config" {
  type        = any
  description = "configMap for AWS EBS CSI Driver add-on"
  default     = {}
}

variable "enable_amazon_eks_vpc_cni" {
  type        = bool
  description = "Enable VPC CNI add-on"
  default     = false
}

variable "enable_amazon_eks_kube_proxy" {
  type        = bool
  description = "Enable Kube Proxy add-on"
  default     = false
}

variable "enable_amazon_eks_aws_ebs_csi_driver" {
  type        = bool
  description = "Enable EKS Managed AWS EBS CSI Driver add-on; enable_amazon_eks_aws_ebs_csi_driver and enable_self_managed_aws_ebs_csi_driver are mutually exclusive"
  default     = false
}

variable "custom_image_registry_uri" {
  type        = map(string)
  description = "Custom image registry URI map of `{region = dkr.endpoint }`"
  default     = {}
}

#-----------CLUSTER AUTOSCALER-------------
variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Enable Cluster autoscaler add-on"
  default     = false
}

variable "cluster_autoscaler_helm_config" {
  type        = any
  description = "Cluster Autoscaler Helm Chart config"
  default     = {}
}

#-----------COREDNS AUTOSCALER-------------
variable "enable_coredns_autoscaler" {
  type        = bool
  description = "Enable CoreDNS autoscaler add-on"
  default     = false
}

variable "coredns_autoscaler_helm_config" {
  type        = any
  description = "CoreDNS Autoscaler Helm Chart config"
  default     = {}
}

#-----------METRIC SERVER-------------
variable "enable_metrics_server" {
  type        = bool
  description = "Enable metrics server add-on"
  default     = false
}

variable "metrics_server_helm_config" {
  type        = any
  description = "Metrics Server Helm Chart config"
  default     = {}
}

#-----------AWS LB Ingress Controller-------------
variable "enable_aws_load_balancer_controller" {
  type        = bool
  description = "Enable AWS Load Balancer Controller add-on"
  default     = false
}

variable "aws_load_balancer_controller_helm_config" {
  type        = any
  description = "AWS Load Balancer Controller Helm Chart config"
  default     = {}
}

#-----------NGINX-------------
variable "enable_ingress_nginx" {
  type        = bool
  description = "Enable Ingress Nginx add-on"
  default     = false
}

variable "ingress_nginx_helm_config" {
  type        = any
  description = "Ingress Nginx Helm Chart config"
  default     = {}
}


#-----------AWS CloudWatch Metrics-------------
variable "enable_aws_cloudwatch_metrics" {
  type        = bool
  description = "Enable AWS CloudWatch Metrics add-on for Container Insights"
  default     = false
}

variable "aws_cloudwatch_metrics_helm_config" {
  type        = any
  description = "AWS CloudWatch Metrics Helm Chart config"
  default     = {}
}

variable "aws_cloudwatch_metrics_irsa_policies" {
  type        = list(string)
  description = "Additional IAM policies for a IAM role for service accounts"
  default     = []
}


#-----------Argo Rollouts ADDON-------------
variable "enable_argo_rollouts" {
  type        = bool
  description = "Enable Argo Rollouts add-on"
  default     = false
}

variable "argo_rollouts_helm_config" {
  type        = any
  description = "Argo Rollouts Helm Chart config"
  default     = null
}

#-----------ARGOCD ADDON-------------
variable "enable_argocd" {
  type        = bool
  description = "Enable Argo CD Kubernetes add-on"
  default     = false
}

variable "argocd_helm_config" {
  type        = any
  description = "Argo CD Kubernetes add-on config"
  default     = {}
}

variable "argocd_applications" {
  type        = any
  description = "Argo CD Applications config to bootstrap the cluster"
  default     = {}
}

variable "argocd_manage_add_ons" {
  type        = bool
  description = "Enable managing add-on configuration via ArgoCD App of Apps"
  default     = false
}

variable "argocd_cert_arn" {
  default     = ""
  type        = string
  description = ""
}

variable "argocd_values" {
  type        = string
  default     = ""
  description = ""
}

#-----------KARPENTER ADDON-------------
variable "enable_karpenter" {
  type        = bool
  description = "Enable Karpenter autoscaler add-on"
  default     = false
}

variable "karpenter_helm_config" {
  type        = any
  description = "Karpenter autoscaler add-on config"
  default     = {}
}

variable "karpenter_irsa_policies" {
  type        = list(string)
  description = "Additional IAM policies for a IAM role for service accounts"
  default     = []
}

variable "karpenter_node_iam_instance_profile" {
  type        = string
  description = "Karpenter Node IAM Instance profile id"
  default     = ""
}

#-----------Kubernetes Dashboard ADDON-------------
variable "enable_kubernetes_dashboard" {
  type        = bool
  description = "Enable Kubernetes Dashboard add-on"
  default     = false
}

variable "kubernetes_dashboard_helm_config" {
  type        = any
  description = "Kubernetes Dashboard Helm Chart config"
  default     = null
}

#-----------AWS CSI Secrets Store Provider-------------
variable "enable_secrets_store_csi_driver_provider_aws" {
  type        = bool
  description = "Enable AWS CSI Secrets Store Provider"
  default     = false
}

variable "csi_secrets_store_provider_aws_helm_config" {
  type        = any
  description = "CSI Secrets Store Provider AWS Helm Configurations"
  default     = null
}

#-----------CSI Secrets Store Provider-------------
variable "enable_secrets_store_csi_driver" {
  type        = bool
  description = "Enable CSI Secrets Store Provider"
  default     = false
}

variable "secrets_store_csi_driver_helm_config" {
  type        = any
  description = "CSI Secrets Store Provider Helm Configurations"
  default     = null
}

#-----------EXTERNAL SECRETS OPERATOR-----------
variable "enable_external_secrets" {
  type        = bool
  description = "Enable External Secrets operator add-on"
  default     = false
}

variable "external_secrets_helm_config" {
  type        = any
  description = "External Secrets operator Helm Chart config"
  default     = {}
}

variable "external_secrets_irsa_policies" {
  type        = list(string)
  description = "Additional IAM policies for a IAM role for service accounts"
  default     = []
}

variable "external_secrets_ssm_parameter_arns" {
  type        = list(string)
  description = "List of Systems Manager Parameter ARNs that contain secrets to mount using External Secrets"
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

variable "external_secrets_secrets_manager_arns" {
  type        = list(string)
  description = "List of Secrets Manager ARNs that contain secrets to mount using External Secrets"
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

#-----------Grafana ADDON-------------
variable "enable_grafana" {
  type        = bool
  description = "Enable Grafana add-on"
  default     = false
}
variable "grafana_helm_config" {
  type        = any
  description = "Kubernetes Grafana Helm Chart config"
  default     = null
}

variable "grafana_irsa_policies" {
  type        = list(string)
  description = "IAM policy ARNs for grafana IRSA"
  default     = []
}

#-----------Datadog Operator-------------
variable "enable_datadog_operator" {
  type        = bool
  description = "Enable Datadog Operator add-on"
  default     = false
}

variable "datadog_operator_helm_config" {
  type        = any
  description = "Datadog Operator Helm Chart config"
  default     = {}
}

#-------Define ArgoCD Managed apps---#

variable "workload" {
  type        = map(any)
  description = "Map of Application manifest values to pass to ArgoCD"
  default     = {}
}

# ------- Service account ------#
variable "service_accounts" {
  type        = map(any)
  description = "A map of service account parameters"
  default     = {}
}

# ------- Cert-Manager Certificates ------ #
variable "certificate_name" {
  type        = string
  description = "name for the certificate"
  default     = "terratest-cert"
}

variable "certificate_dns" {
  type        = string
  description = "CommonName used in the Certificate, usually DNS"
  default     = "test-domain.com"
}

variable "cert_manager_helm_config" {
  description = "Cert Manager Helm Chart config"
  type        = any
  default     = {}
}

variable "cert_manager_irsa_policies" {
  description = "Additional IAM policies for a IAM role for service accounts"
  type        = list(string)
  default     = []
}

variable "cert_manager_domain_names" {
  description = "Domain names of the Route53 hosted zone to use with cert-manager"
  type        = list(string)
  default     = []
}