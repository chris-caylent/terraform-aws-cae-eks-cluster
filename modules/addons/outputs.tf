output "argocd" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.argocd[0], null)
}

output "aws_cloudwatch_metrics" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_cloudwatch_metrics[0], null)
}

output "aws_coredns" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_coredns[0], null)
}

output "aws_kube_proxy" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_kube_proxy[0], null)
}

output "aws_load_balancer_controller" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_load_balancer_controller[0], null)
}

output "aws_privateca_issuer" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_privateca_issuer[0], null)
}

output "aws_vpc_cni" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.aws_vpc_cni[0], null)
}

output "cert_manager" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.cert_manager[0], null)
}

output "cert_manager_csi_driver" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.cert_manager_csi_driver[0], null)
}

output "coredns_autoscaler" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.coredns_autoscaler[0], null)
}

output "csi_secrets_store_provider_aws" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.csi_secrets_store_provider_aws[0], null)
}

output "datadog_agent" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.datadog_agent[0], null)
}

output "splunk" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.splunk[0], null)
}

output "metrics_server" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.metrics_server[0], null)
}
output "secrets_store_csi_driver" {
  description = "Map of attributes of the Helm release and IRSA created"
  value       = try(module.secrets_store_csi_driver[0], null)
}