variable "eks_cluster_id" {
  description = "EKS Cluster Id"
  type        = string
}

variable "eks_cluster_domain" {
  description = "The domain for the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_worker_security_group_id" {
  description = "EKS Worker Security group Id created by EKS module"
  type        = string
  default     = ""
}

variable "data_plane_wait_arn" {
  description = "Addon deployment will not proceed until this value is known. Set to node group/Fargate profile ARN to wait for data plane to be ready before provisioning addons"
  type        = string
  default     = ""
}

variable "auto_scaling_group_names" {
  description = "List of self-managed node groups autoscaling group names"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
  type        = map(string)
  default     = {}
}

variable "irsa_iam_role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
  type        = string
  default     = ""
}

variable "eks_oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  type        = string
  default     = null
}

variable "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  type        = string
  default     = null
}

variable "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  type        = string
  default     = null
}

#-----------EKS MANAGED ADD-ONS------------
variable "enable_ipv6" {
  description = "Enable Ipv6 network. Attaches new VPC CNI policy to the IRSA role"
  type        = bool
  default     = false
}

variable "amazon_eks_vpc_cni_config" {
  description = "ConfigMap of Amazon EKS VPC CNI add-on"
  type        = any
  default     = {}
}

variable "enable_amazon_eks_coredns" {
  description = "Enable Amazon EKS CoreDNS add-on"
  type        = bool
  default     = false
}

variable "amazon_eks_coredns_config" {
  description = "Configuration for Amazon CoreDNS EKS add-on"
  type        = any
  default     = {}
}

variable "remove_default_coredns_deployment" {
  description = "Determines whether the default deployment of CoreDNS is removed and ownership of kube-dns passed to Helm"
  type        = bool
  default     = false
}

variable "enable_coredns_cluster_proportional_autoscaler" {
  description = "Enable cluster-proportional-autoscaler for CoreDNS"
  type        = bool
  default     = true
}

variable "coredns_cluster_proportional_autoscaler_helm_config" {
  description = "Helm provider config for the CoreDNS cluster-proportional-autoscaler"
  default     = {}
  type        = any
}


variable "amazon_eks_kube_proxy_config" {
  description = "ConfigMap for Amazon EKS Kube-Proxy add-on"
  type        = any
  default     = {}
}

variable "amazon_eks_aws_ebs_csi_driver_config" {
  description = "configMap for AWS EBS CSI Driver add-on"
  type        = any
  default     = {}
}

variable "enable_amazon_eks_vpc_cni" {
  description = "Enable VPC CNI add-on"
  type        = bool
  default     = false
}

variable "enable_amazon_eks_kube_proxy" {
  description = "Enable Kube Proxy add-on"
  type        = bool
  default     = false
}

variable "enable_amazon_eks_aws_ebs_csi_driver" {
  description = "Enable EKS Managed AWS EBS CSI Driver add-on; enable_amazon_eks_aws_ebs_csi_driver and enable_self_managed_aws_ebs_csi_driver are mutually exclusive"
  type        = bool
  default     = false
}

variable "custom_image_registry_uri" {
  description = "Custom image registry URI map of `{region = dkr.endpoint }`"
  type        = map(string)
  default     = {}
}

#-----------CLUSTER AUTOSCALER-------------
variable "enable_cluster_autoscaler" {
  description = "Enable Cluster autoscaler add-on"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_helm_config" {
  description = "Cluster Autoscaler Helm Chart config"
  type        = any
  default     = {}
}

#-----------COREDNS AUTOSCALER-------------
variable "enable_coredns_autoscaler" {
  description = "Enable CoreDNS autoscaler add-on"
  type        = bool
  default     = false
}

variable "coredns_autoscaler_helm_config" {
  description = "CoreDNS Autoscaler Helm Chart config"
  type        = any
  default     = {}
}


#-----------PROMETHEUS-------------
variable "enable_prometheus" {
  description = "Enable Community Prometheus add-on"
  type        = bool
  default     = false
}

variable "prometheus_helm_config" {
  description = "Community Prometheus Helm Chart config"
  type        = any
  default     = {}
}


#-----------METRIC SERVER-------------
variable "enable_metrics_server" {
  description = "Enable metrics server add-on"
  type        = bool
  default     = false
}

variable "metrics_server_helm_config" {
  description = "Metrics Server Helm Chart config"
  type        = any
  default     = {}
}

#-----------AWS LB Ingress Controller-------------
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller add-on"
  type        = bool
  default     = false
}

variable "aws_load_balancer_controller_helm_config" {
  description = "AWS Load Balancer Controller Helm Chart config"
  type        = any
  default     = {}
}

#-----------NGINX-------------
variable "enable_ingress_nginx" {
  description = "Enable Ingress Nginx add-on"
  type        = bool
  default     = false
}

variable "ingress_nginx_helm_config" {
  description = "Ingress Nginx Helm Chart config"
  type        = any
  default     = {}
}


#-----------AWS CloudWatch Metrics-------------
variable "enable_aws_cloudwatch_metrics" {
  description = "Enable AWS CloudWatch Metrics add-on for Container Insights"
  type        = bool
  default     = false
}

variable "aws_cloudwatch_metrics_helm_config" {
  description = "AWS CloudWatch Metrics Helm Chart config"
  type        = any
  default     = {}
}

variable "aws_cloudwatch_metrics_irsa_policies" {
  description = "Additional IAM policies for a IAM role for service accounts"
  type        = list(string)
  default     = []
}


#-----------Argo Rollouts ADDON-------------
variable "enable_argo_rollouts" {
  description = "Enable Argo Rollouts add-on"
  type        = bool
  default     = false
}

variable "argo_rollouts_helm_config" {
  description = "Argo Rollouts Helm Chart config"
  type        = any
  default     = null
}

#-----------ARGOCD ADDON-------------
variable "enable_argocd" {
  description = "Enable Argo CD Kubernetes add-on"
  type        = bool
  default     = false
}

variable "argocd_helm_config" {
  description = "Argo CD Kubernetes add-on config"
  type        = any
  default     = {}
}

variable "argocd_applications" {
  description = "Argo CD Applications config to bootstrap the cluster"
  type        = any
  default     = {}
}

variable "argocd_manage_add_ons" {
  description = "Enable managing add-on configuration via ArgoCD App of Apps"
  type        = bool
  default     = false
}


#-----------KARPENTER ADDON-------------
variable "enable_karpenter" {
  description = "Enable Karpenter autoscaler add-on"
  type        = bool
  default     = false
}

variable "karpenter_helm_config" {
  description = "Karpenter autoscaler add-on config"
  type        = any
  default     = {}
}

variable "karpenter_irsa_policies" {
  description = "Additional IAM policies for a IAM role for service accounts"
  type        = list(string)
  default     = []
}

variable "karpenter_node_iam_instance_profile" {
  description = "Karpenter Node IAM Instance profile id"
  type        = string
  default     = ""
}

#-----------Kubernetes Dashboard ADDON-------------
variable "enable_kubernetes_dashboard" {
  description = "Enable Kubernetes Dashboard add-on"
  type        = bool
  default     = false
}

variable "kubernetes_dashboard_helm_config" {
  description = "Kubernetes Dashboard Helm Chart config"
  type        = any
  default     = null
}


#-----------AWS CSI Secrets Store Provider-------------
variable "enable_secrets_store_csi_driver_provider_aws" {
  type        = bool
  default     = false
  description = "Enable AWS CSI Secrets Store Provider"
}

variable "csi_secrets_store_provider_aws_helm_config" {
  type        = any
  default     = null
  description = "CSI Secrets Store Provider AWS Helm Configurations"
}

#-----------CSI Secrets Store Provider-------------
variable "enable_secrets_store_csi_driver" {
  type        = bool
  default     = false
  description = "Enable CSI Secrets Store Provider"
}

variable "secrets_store_csi_driver_helm_config" {
  type        = any
  default     = null
  description = "CSI Secrets Store Provider Helm Configurations"
}

#-----------EXTERNAL SECRETS OPERATOR-----------
variable "enable_external_secrets" {
  type        = bool
  default     = false
  description = "Enable External Secrets operator add-on"
}

variable "external_secrets_helm_config" {
  type        = any
  default     = {}
  description = "External Secrets operator Helm Chart config"
}

variable "external_secrets_irsa_policies" {
  description = "Additional IAM policies for a IAM role for service accounts"
  type        = list(string)
  default     = []
}

variable "external_secrets_ssm_parameter_arns" {
  description = "List of Systems Manager Parameter ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:ssm:*:*:parameter/*"]
}

variable "external_secrets_secrets_manager_arns" {
  description = "List of Secrets Manager ARNs that contain secrets to mount using External Secrets"
  type        = list(string)
  default     = ["arn:aws:secretsmanager:*:*:secret:*"]
}

#-----------Grafana ADDON-------------
variable "enable_grafana" {
  description = "Enable Grafana add-on"
  type        = bool
  default     = false
}
variable "grafana_helm_config" {
  description = "Kubernetes Grafana Helm Chart config"
  type        = any
  default     = null
}

variable "grafana_irsa_policies" {
  description = "IAM policy ARNs for grafana IRSA"
  type        = list(string)
  default     = []
}

#-----------Datadog Agent-------------
variable "enable_datadog_agent" {
  description = "Enable Datadog Operator add-on"
  type        = bool
  default     = false
}

variable "datadog_agent_helm_config" {
  description = "Datadog Operator Helm Chart config"
  type        = any
  default     = {}
}

#-----------SPLUNK KUBERNETES LOGGING-------------
variable "enable_splunk_logging" {
  description = "Enable Splunk Agent add-on"
  type        = bool
  default     = false
}

variable "splunk_helm_config" {
  description = "Splunk Agent Helm Chart config"
  type        = any
  default     = {}
}

#-----------CERT MANAGER-------------
variable "enable_cert_manager" {
  description = "Enable Cert Manager add-on"
  type        = bool
  default     = false
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

variable "cert_manager_install_letsencrypt_issuers" {
  description = "Install Let's Encrypt Cluster Issuers"
  type        = bool
  default     = true
}

variable "cert_manager_letsencrypt_email" {
  description = "Email address for expiration emails from Let's Encrypt"
  type        = string
  default     = ""
}

variable "enable_cert_manager_csi_driver" {
  description = "Enable Cert Manager CSI Driver add-on"
  type        = bool
  default     = false
}

variable "cert_manager_csi_driver_helm_config" {
  description = "Cert Manager CSI Driver Helm Chart config"
  type        = any
  default     = {}
}

variable "cert_manager_kubernetes_svc_image_pull_secrets" {
  description = "list(string) of kubernetes imagePullSecrets"
  type        = list(string)
  default     = []
}

#-----------AWS PCA ISSUER-------------
variable "enable_aws_privateca_issuer" {
  description = "Enable PCA Issuer"
  type        = bool
  default     = false
}

variable "aws_privateca_issuer_helm_config" {
  description = "PCA Issuer Helm Chart config"
  type        = any
  default     = {}
}

variable "aws_privateca_acmca_arn" {
  description = "ARN of AWS ACM PCA"
  type        = string
  default     = ""
}

variable "aws_privateca_issuer_irsa_policies" {
  description = "IAM policy ARNs for AWS ACM PCA IRSA"
  type        = list(string)
  default     = []
}
