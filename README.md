# terraform-aws-cae-eks-cluster

This module provisions additional resources to assemble a fully functional EKS cluster with:

- Managed node groups
- IRSA - IAM roles for service accounts
- KMS
- Teams (platform and application)
- AWS auth configmaps for approriate user permissions.

## Requisites

- [tfenv](https://github.com/tfutils/tfenv) - This is used in order to manage different Terraform versions
- [terraform-docs](https://github.com/segmentio/terraform-docs) - This is used in our pre-commit hook in order to generate documentation from Terraform modules in various output formats.
- [pre-commit](https://pre-commit.com/#install)-configuration to run code standardization (terraform fmt) and documentation (terraform docs) automation on `git commit`
- [Granted](https://docs.commonfate.io/granted/getting-started) (optional) - tooling to help assume your SSO role into an AWS account
- Public cloud provider access credentials (if not using Granted)

---------------------

## Prerequisites

This codebase uses the following Terraform and Golang versions.  Code has not be tested and verified to work with any other versions other than what is listed below:

- Terraform: 1.2.0
- Go: 1.18

### Installation Steps (MacOS)

```sh
brew install pre-commit gawk terraform-docs coreutils tfenv awscli jq cfn-lint
```

### **tfenv**

---------------------

##### List current Terraform versions installed on your system

```sh
tfenv list
```

##### Install a specific version of Terraform

```sh
tfenv install 1.2.0
```

##### Select Terraform version to be used, this could be used to switch between versions

```sh
tfenv use 1.2.0
```

### **pre-commit**

---------------------

#### Pre-Commit Usage

- [Pre-Commit documentation](https://pre-commit.com/)
- [Hook documentation](https://github.com/antonbabenko/pre-commit-terraform)

You must `git add .` your files before the pre-commit hook will run against them.

##### Check the version

```sh
pre-commit --version
```

##### Install the git hook scripts

```sh
pre-commit install
```

##### Run against all files (`git add` must be run first)

```sh
pre-commit run -a
```

## Authenticate to AWS environments with Granted (Optional)

---------------------

Below are steps to ensure easy access to AWS environments by assuming your SSO role with [Granted](https://docs.commonfate.io/granted/getting-started)

```sh
# install with Homebrew
brew tap common-fate/granted
brew install granted

# verify installation
➜ granted -v

Granted v0.3.0
```

### **Setup your AWS profile**

Follow the steps as outlined by executing the command in your terminal: `aws configure sso`

```sh
aws configure sso
> SSO start URL [None]: <Start URL> (the redirect URL after you login to AWS Control Tower through an SSO provider)
> SSO Region: us-west-2

# after the above values are entered your browser will open to and have you confirm
# a few prompts.  Allow the authorize request.

#When successful, you will see a "Request Approved" AWS Modal in your browser tab.

# Go back to the Terminal session to finish the prompts

# Pick the account to which you wish to create a profile, you may also see all accounts to which you have access.

# Pick your assigned role, this will vary based on your organization
# Default CLI region: us-west-2
# Output format: JSON

# CLI Profile name: you can keep what is generated (not recommended) or use something explicit to the environment, like "shared-services-admin"

```

Test your credentials

```sh
$ assume
 Please select the profile you would like to assume:  [Use arrows to move, type to filter]
> shared-services-admin (this is the profile you created in the previous step)

# You will then see a message like: 
[shared-services-admin](us-west-2) session credentials will expire 2022-09-27 14:15:48 -0400 EDT
>

# check to be sure you can query sts and receive your assume role arn back
$ aws sts get-caller-identiy
> 
{
    "UserId": "(redacted):chris.gonzalez@caylent.com",
    "Account": "1111111111",
    "Arn": "arn:aws:sts::1111111111:assumed-role/AWSReservedSSO_AWSPowerUserAccess_(redacted)/chris.gonzalez@caylent.com"
}

# if the above commands are successful, then you can now use Terraform or Run terrestest from your local machine
```

#### **Go**

---------------------

```sh

# Update and Install Go (for a specfic version, append @{version}, like `brew install golang@1.18`)
brew update && brew install go@1.18

# Following Go best practices, create 3 new directories ($HOME/go/bin, $HOME/go/src, $HOME/go/pkg)
mkdir -p $HOME/go/{bin,src,pkg}

# Set important environment variables
# Add the below to your .bashrc, or .zshrc
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# If you're on an M1 mac, make Go play nicely with Rosetta
export GODEBUG=asyncpreemptoff=1

# source your shell
source $HOME/.bashrc (or .zshrc)
```

## **Terratest - Recommended Test Practices**

---------------------

## Use table driven tests

- These tests are a fairly standard practice
- They let you clearly and easily create multiple test-cases for a single test
- They are defined as an array of structs, where fields of the struct are variables for each test case

## When defining essential variables, **USE** hard-coded fixed fields

- Repository examples should hard-code fixed fields, which are essential to the spirit of the example

## When defining field variables to be tested, **DO NOT USE** use hard-coded fixed fields

- Repository examples should use variables for fields which are to be tested (i.e., so that they can be fed in via terratest)

## Useful packages

- [testify/assert library](https://github.com/stretchr/testify/assert) -- assertion library to assert test results against expected fields
- [aws api helper library](https://github.com/gruntwork-io/terratest/modules/aws) -- library to help us query the AWS API directly

## Helpful terminal commands

_You must be authenticated to the target AWS account before executing the below commands_

```sh
# run all tests cases with no verbose output (not recommended, as you can't see errors)
go test

# apply verbose output and extend the timeout past the default of 10m (helpful for tests that need longer to run -- like AWS RDS examples)
go test -v -timeout 30m

# run a single test, be sure the test case matches the regex TestSimpleDynamoDb
to test run TestSimpleDynamoDb

# print the test output to a file
go test -v -timeout 30m | tee ~/Desktop/module_terratest_output.txt

# use a make file to document the test output for longer tests (optional)
make test | tee ~/Desktop/module_terratest_output.txt
```

#### Supporting Documentation

- [Terratest documentation](https://terratest.gruntwork.io/docs/#getting-started)


### **Terraform**

---------------------

Prerequisites:

- You can successfully authenticate to AWS via CLI using Granted or your preferred method of authentication.
- You have the correct version of Terraform installed through `tfenv`

When developing modules, it is easier to run these commands from your example directory where you have already defined an example for your tests to run against.

Navigate to the directory where you would like to run your terraform configuration, authenticate to AWS through the CLI (optionally through Granted)

```hcl
terraform init (install modules, both local and external)
terraform validate (validate your configuration will not error before the plan/apply stage)
terraform plan (check what you're going to provision)
terraform apply (deploy the infrastructure)
terraform destroy (destroy the infrastructure)
```

## Initial Deployment and Validation

Before you begin, be sure you have appropriate external configurations in place such as AWS Secrets Manager Secrets and any IAM roles are users needed by this configuration.

The commands below assume you are simply testing the example configuration and are using only a local backend for tfstate.

```hcl

terraform init

terraform validate

terraform plan -var-file fixtures.us-west-2.tfvars

terraform apply -var-file varfile.tfvars
```

Be sure to destroy resources in the reverse order (in development settings only):

```hcl
terraform destroy -target module.addons -var-file varfile.tfvars
terraform destroy -target module.eks_cluster -var-file varfile.tfvars
terraform destroy -target module.vpc -var-file varfile.tfvars
terraform destroy -target -var-file varfile.tfvars
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

  enable_cert_manager            = false
  cert_manager_irsa_policies     = [aws_iam_policy.cert-manager-cross-account.arn] 
  

  tags = local.tags
}


################################################################################
# Supporting resources -- VPC
################################################################################

module "vpc" {
  source = "../../modules/vpc" # not implemented in this module

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

## Examples

- [eks-example-cluster](./examples/eks-example-cluster/)
## Secrets

AWS Secrets manager is used to store git repository credentials so that ArgoCD can automatically set up applications.  Before deploying anything related to ArgoCD, you must have secret created with the keys `USERNAME` and `PASSWORD`.  This will allow ArgoCD to authenticate to Codecommit (or a private repo of your choosing) using the access credentials of an IAM user already in your AWS account.

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
    app-1 = var.app-1
    app-2 = var.app-2
    app-3 = var.app-3
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

## Terratest

An example Terratest is provided in `/test/eks-example-cluster_test.go`

In order to run the test you must have the Go programming language binaries installed on your local machine.

Test commands:

```sh

```
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
| <a name="module_eks_core"></a> [eks\_core](#module\_eks\_core) | ./modules/eks-core | n/a |
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