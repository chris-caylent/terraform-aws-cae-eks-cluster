# terraform-pyx-aws-eks-core

Terraform module that creates core resources for EKS on AWS. This module provisions base resources like:

- Base EKS deployment with no additional features (like load balancers, ArgoCD, Cloudwatch Metrics, etc)
- Cloudwatch Log Group
- Default security groups for the cluster allowing egress/ingress to port 443 and to K8S API in the kubelets.
- Cluster IAM roles, assume roles, Cluster policies
- Encryption with KMS (external KMS module)

## Deployment

- A VPC must be deployed before this module is deployed, as resources inside of this module depend on them.
- Deployment time takes around 15 - 20 minutes

Optional deployment strategy -- resource targeting

```sh
# deploy a vpc configuration first
terraform apply -auto-approve -target module.vpc

# once a VPC is in the environment, deploy the base cluster
terraform apply -auto-approve -target module.eks_cluster

# destroy resources in the reverse (this should only be done in a development setting)
terraform destroy -auto-approve -target module.eks_cluster
terraform destroy -auto-approve -target module.vpc

```

## Usage

```hcl
module "eks_cluster" {
  source = "../../"

  cluster_name    = var.cluster_name
  cluster_version = "1.23"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets

  managed_node_groups = {
    mg_5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      min_size        = 3
      max_size        = 3
      desired_size    = 3
      subnet_ids      = module.vpc.private_subnets
    }
  }

  tags = var.tags
}
```

### External Documentation

Please familiarize yourself with EKS and Kubernetes documentation so that the concepts discussed are able to be comprehended:

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
