# IRSA (IAM roles for Kubernetes Service Accounts)

This Terraform module creates the following resources

1. Kubernetes Namespace for Kubernetes Addon
2. Service Account for Kubernetes Addon
3. IAM Role for Service Account with OIDC assume role policy
4. Creates default policy required for Addon
5. Attaches the additional IAM policies provided by consumer module

## Helpful AWS docs resources

- [Introducing fine-grained IAM roles for service accounts](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)
- [Cross account IAM roles for Kubernetes service accounts](https://aws.amazon.com/blogs/containers/cross-account-iam-roles-for-kubernetes-service-accounts/)
- [Enabling cross-account access to Amazon EKS cluster resources](https://aws.amazon.com/blogs/containers/enabling-cross-account-access-to-amazon-eks-cluster-resources/)