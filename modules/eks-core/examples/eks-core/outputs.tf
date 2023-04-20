#-------------------------------
# EKS Cluster Module Outputs
#-------------------------------
output "eks_cluster_arn" {
  description = "Amazon EKS Cluster Name"
  value       = module.eks_core.cluster_arn
}

output "eks_cluster_id" {
  description = "Amazon EKS Cluster Name"
  value       = module.eks_core.cluster_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_core.cluster_certificate_authority_data
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks_core.cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks_core.cluster_id}"
}

output "eks_cluster_status" {
  description = "Amazon EKS Cluster Status"
  value       = module.eks_core.cluster_status
}

output "eks_cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = module.eks_core.cluster_version
}

#-------------------------------
# KMS outputs
#-------------------------------

output "key_id" {
  description = "The globally unique identifier for the key."
  value       = aws_kms_key.test_kms_key.id
}

output "key_arn" {
  description = "The Amazon Resource Name (ARN) of the key."
  value       = aws_kms_key.test_kms_key.arn
}
