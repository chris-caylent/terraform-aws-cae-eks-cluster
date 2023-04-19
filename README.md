# terraform-aws-cae-eks-cluster

This module provisions additional resources to assemble a fully functional EKS cluster with:

- Managed node groups
- IRSA - IAM roles for service accounts
- KMS
- Teams (platform and application)
- AWS auth configmaps for approriate user permissions.

## Examples

- [eks-cluster-with-core-addons](./examples/eks-cluster-with-core-addons/)

## Initial Deployment

```hcl
terraform apply -auto-approve -var-file varfile.tfvars
```

Be sure to destroy resources in the reverse order (in development settings only):

```hcl
terraform destroy -auto-approve -target module.addons -var-file varfile.tfvars
terraform destroy -auto-approve -target module.eks_cluster -var-file varfile.tfvars
terraform destroy -auto-approve -target module.vpc -var-file varfile.tfvars
terraform destroy -auto-approve -var-file varfile.tfvars
```

## Usage

```hcl

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

module "eks_cluster" {
  source = "../../"

  cluster_name    = local.cluster_name
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
    workload = local.
    #workloads = local.workload_application
  }


  argocd_helm_config = {
  }

  # let argo cd manage the addons
  argocd_manage_add_ons = true

  # EKS Managed Add-ons
  enable_amazon_eks_vpc_cni           = true
  enable_amazon_eks_coredns           = true
  enable_amazon_eks_kube_proxy        = true
  enable_aws_load_balancer_controller = true
  enable_aws_cloudwatch_metrics       = true

  # Add-ons
  # enable_metrics_server               = true

  tags = local.tags
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

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl = true
  default_network_acl_tags   = { Name = "${local.cluster_name}-default" }

  manage_default_route_table = true
  default_route_table_tags   = { Name = "${local.cluster_name}-default" }

  manage_default_security_group = true
  default_security_group_tags   = { Name = "${local.cluster_name}-default" }

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
```

## Secrets

AWS Secrets manager is used to store git repository credentials so that ArgoCD can automatically set up applications.  Before deploying anything related to ArgoCD, you must have secret created with the keys `USERNAME` and `PASSWORD`.  This will allow ArgoCD to authenticate to Codecommit using the access credentials of the gitlab-to-aws-user already in each AWS account.

## Automated ArgoCD application setup

This method supports 1..n applications.

After creating a valid repo credential secret in AWS Secrets Manager, pass in your application configuration from top level repository (such as pyx-data-collector-application):

```hcl
app-1 = {
  path                    = "workload"
  target_revision         = "main" 
  repo_url                = "https://helm-chart-repo.com"
  values                  = "environments/dev/values.yaml"
  namespace               = "workload-namespace"
  https_credential_secret = "argocd-git-repo-credentials" # the name of the repo credentials secret
  add_on_application      = false
}

# in main.tf of top-level application repo

module "addons" {
  ...omitted for brevity
  argocd_applications = {
    app-1   = var.app-1
    app-2   = var.app-2
    app-3   = var.app-3
  }

```
## Validate ArgoCD deployment

Assuming you can run `kubectl` commands against the cluster you should be able to query ArgoCD service details.  Please wait about 2 minutes before the LoadBalancer is live.

Run the following in the CLI:

```sh
export ARGOCD_SERVER=`kubectl get svc argo-cd-argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
echo "https://$ARGOCD_SERVER"

```

## Access ArgoCD WebUI

Navigate to the AWS console --> EC2 --> Load Balancers

Copy the DNS name A record for the ALB

Run the below command to query for the admin password to the ArgoCD UI in your CLI (you must be authenticated to your AWS account and EKS cluster)

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Login to the UI:

- Username: admin
- Password: the result of the query above.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.28 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.28 |
| <a name="provider_http"></a> [http](#provider\_http) | 2.4.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_core"></a> [eks\_core](#module\_eks\_core) | git::ssh://git@git.perceptyx.com:/tiger-team/terraform-aws-pyx-eks-core.git | v1.0.0 |
| <a name="module_eks_managed_node_group"></a> [eks\_managed\_node\_group](#module\_eks\_managed\_node\_group) | ./modules/managed-node-group | n/a |
| <a name="module_eks_teams"></a> [eks\_teams](#module\_eks\_teams) | ./modules/eks-teams | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ./modules/kms | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.eks_key](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/4.28/docs/data-sources/region) | data source |
| [http_http.eks_cluster_readiness](https://registry.terraform.io/providers/terraform-aws-modules/http/2.4.1/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_teams"></a> [application\_teams](#input\_application\_teams) | Map of maps of Application Teams to create | `any` | `{}` | no |
| <a name="input_aws_auth_additional_labels"></a> [aws\_auth\_additional\_labels](#input\_aws\_auth\_additional\_labels) | Additional kubernetes labels applied on aws-auth ConfigMap | `map(string)` | `{}` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html) | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain log events. Default retention - 90 days | `number` | `90` | no |
| <a name="input_cluster_additional_security_group_ids"></a> [cluster\_additional\_security\_group\_ids](#input\_cluster\_additional\_security\_group\_ids) | List of additional, externally created security group IDs to attach to the cluster control plane | `list(string)` | `[]` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logging to enable | `list(string)` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | Configuration block with encryption configuration for the cluster | <pre>list(object({<br>    provider_key_arn = string<br>    resources        = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the EKS private API server endpoint is enabled. Default to EKS resource and it is false | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the EKS public API server endpoint is enabled. Default to EKS resource and it is true | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cluster_identity_providers"></a> [cluster\_identity\_providers](#input\_cluster\_identity\_providers) | Map of cluster identity provider configurations to enable for the cluster. Note - this is different/separate from IRSA | `any` | `{}` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created | `string` | `"ipv4"` | no |
| <a name="input_cluster_kms_key_additional_admin_arns"></a> [cluster\_kms\_key\_additional\_admin\_arns](#input\_cluster\_kms\_key\_additional\_admin\_arns) | A list of additional IAM ARNs that should have FULL access (kms:*) in the KMS key policy | `list(string)` | `[]` | no |
| <a name="input_cluster_kms_key_arn"></a> [cluster\_kms\_key\_arn](#input\_cluster\_kms\_key\_arn) | A valid EKS Cluster KMS Key ARN to encrypt Kubernetes secrets | `string` | `null` | no |
| <a name="input_cluster_kms_key_deletion_window_in_days"></a> [cluster\_kms\_key\_deletion\_window\_in\_days](#input\_cluster\_kms\_key\_deletion\_window\_in\_days) | The waiting period, specified in number of days (7 - 30). After the waiting period ends, AWS KMS deletes the KMS key | `number` | `30` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster Name | `string` | `""` | no |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source | `any` | `{}` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Security group to be used if creation of cluster security group is turned off | `string` | `""` | no |
| <a name="input_cluster_security_group_tags"></a> [cluster\_security\_group\_tags](#input\_cluster\_security\_group\_tags) | A map of additional tags to add to the cluster security group created | `map(string)` | `{}` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_service_ipv6_cidr"></a> [cluster\_service\_ipv6\_cidr](#input\_cluster\_service\_ipv6\_cidr) | The IPV6 Service CIDR block to assign Kubernetes service IP addresses | `string` | `null` | no |
| <a name="input_cluster_timeouts"></a> [cluster\_timeouts](#input\_cluster\_timeouts) | Create, update, and delete timeout configurations for the cluster | `map(string)` | `{}` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.23`) | `string` | `"1.23"` | no |
| <a name="input_control_plane_subnet_ids"></a> [control\_plane\_subnet\_ids](#input\_control\_plane\_subnet\_ids) | A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane | `list(string)` | `[]` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled | `bool` | `false` | no |
| <a name="input_create_cluster_security_group"></a> [create\_cluster\_security\_group](#input\_create\_cluster\_security\_group) | Toggle to create or assign cluster security group | `bool` | `true` | no |
| <a name="input_create_eks"></a> [create\_eks](#input\_create\_eks) | Create EKS cluster | `bool` | `true` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether a an IAM role is created or to use an existing IAM role | `bool` | `true` | no |
| <a name="input_create_node_security_group"></a> [create\_node\_security\_group](#input\_create\_node\_security\_group) | Determines whether to create a security group for the node groups or use the existing `node_security_group_id` | `bool` | `true` | no |
| <a name="input_custom_oidc_thumbprints"></a> [custom\_oidc\_thumbprints](#input\_custom\_oidc\_thumbprints) | Additional list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s) | `list(string)` | `[]` | no |
| <a name="input_eks_readiness_timeout"></a> [eks\_readiness\_timeout](#input\_eks\_readiness\_timeout) | The maximum time (in seconds) to wait for EKS API server endpoint to become healthy | `number` | `"600"` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Determines whether to create an OpenID Connect Provider for EKS to enable IRSA | `bool` | `true` | no |
| <a name="input_iam_role_additional_policies"></a> [iam\_role\_additional\_policies](#input\_iam\_role\_additional\_policies) | Additional policies to be added to the IAM role | `list(string)` | `[]` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Existing IAM role ARN for the cluster. Required if `create_iam_role` is set to `false` | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Cluster IAM role path | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_managed_node_groups"></a> [managed\_node\_groups](#input\_managed\_node\_groups) | Managed node groups configuration | `any` | `{}` | no |
| <a name="input_map_accounts"></a> [map\_accounts](#input\_map\_accounts) | Additional AWS account numbers to add to the aws-auth ConfigMap | `list(string)` | `[]` | no |
| <a name="input_map_roles"></a> [map\_roles](#input\_map\_roles) | Additional IAM roles to add to the aws-auth ConfigMap | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_map_users"></a> [map\_users](#input\_map\_users) | Additional IAM users to add to the aws-auth ConfigMap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source | `any` | `{}` | no |
| <a name="input_node_security_group_tags"></a> [node\_security\_group\_tags](#input\_node\_security\_group\_tags) | A map of additional tags to add to the node security group created | `map(string)` | `{}` | no |
| <a name="input_openid_connect_audiences"></a> [openid\_connect\_audiences](#input\_openid\_connect\_audiences) | List of OpenID Connect audience client IDs to add to the IRSA provider | `list(string)` | `[]` | no |
| <a name="input_platform_teams"></a> [platform\_teams](#input\_platform\_teams) | Map of maps of platform teams to create | `any` | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnets Ids for the cluster and worker nodes | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnets Ids for the worker nodes | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map('BusinessUnit`,`XYZ`) | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC Id | `string` | n/a | yes |
| <a name="input_worker_additional_security_group_ids"></a> [worker\_additional\_security\_group\_ids](#input\_worker\_additional\_security\_group\_ids) | A list of additional security group ids to attach to worker instances | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console |
| <a name="output_cluster_security_group_arn"></a> [cluster\_security\_group\_arn](#output\_cluster\_security\_group\_arn) | Amazon Resource Name (ARN) of the cluster security group |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | EKS Control Plane Security Group ID |
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig |
| <a name="output_eks_cluster_arn"></a> [eks\_cluster\_arn](#output\_eks\_cluster\_arn) | Amazon EKS Cluster Name |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | Endpoint for your Kubernetes API server |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | Amazon EKS Cluster Name |
| <a name="output_eks_cluster_status"></a> [eks\_cluster\_status](#output\_eks\_cluster\_status) | Amazon EKS Cluster Status |
| <a name="output_eks_cluster_version"></a> [eks\_cluster\_version](#output\_eks\_cluster\_version) | The Kubernetes version for the cluster |
| <a name="output_eks_oidc_issuer_url"></a> [eks\_oidc\_issuer\_url](#output\_eks\_oidc\_issuer\_url) | The URL on the EKS cluster OIDC Issuer |
| <a name="output_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#output\_eks\_oidc\_provider\_arn) | The ARN of the OIDC Provider if `enable_irsa = true`. |
| <a name="output_managed_node_group_arn"></a> [managed\_node\_group\_arn](#output\_managed\_node\_group\_arn) | Managed node group arn |
| <a name="output_managed_node_group_aws_auth_config_map"></a> [managed\_node\_group\_aws\_auth\_config\_map](#output\_managed\_node\_group\_aws\_auth\_config\_map) | Managed node groups AWS auth map |
| <a name="output_managed_node_group_iam_instance_profile_arns"></a> [managed\_node\_group\_iam\_instance\_profile\_arns](#output\_managed\_node\_group\_iam\_instance\_profile\_arns) | IAM instance profile arn's of managed node groups |
| <a name="output_managed_node_group_iam_instance_profile_id"></a> [managed\_node\_group\_iam\_instance\_profile\_id](#output\_managed\_node\_group\_iam\_instance\_profile\_id) | IAM instance profile id of managed node groups |
| <a name="output_managed_node_group_iam_role_arns"></a> [managed\_node\_group\_iam\_role\_arns](#output\_managed\_node\_group\_iam\_role\_arns) | IAM role arn's of managed node groups |
| <a name="output_managed_node_group_iam_role_names"></a> [managed\_node\_group\_iam\_role\_names](#output\_managed\_node\_group\_iam\_role\_names) | IAM role names of managed node groups |
| <a name="output_managed_node_groups"></a> [managed\_node\_groups](#output\_managed\_node\_groups) | Outputs from EKS Managed node groups |
| <a name="output_managed_node_groups_id"></a> [managed\_node\_groups\_id](#output\_managed\_node\_groups\_id) | EKS Managed node groups id |
| <a name="output_managed_node_groups_status"></a> [managed\_node\_groups\_status](#output\_managed\_node\_groups\_status) | EKS Managed node groups status |
| <a name="output_oidc_provider"></a> [oidc\_provider](#output\_oidc\_provider) | The OpenID Connect identity provider (issuer URL without leading `https://`) |
| <a name="output_worker_node_security_group_arn"></a> [worker\_node\_security\_group\_arn](#output\_worker\_node\_security\_group\_arn) | Amazon Resource Name (ARN) of the worker node shared security group |
| <a name="output_worker_node_security_group_id"></a> [worker\_node\_security\_group\_id](#output\_worker\_node\_security\_group\_id) | ID of the worker node shared security group |
<!-- END_TF_DOCS -->