variable "create_eks" {
  type        = bool
  description = "Controls if EKS resources should be created (affects nearly all resources)"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "prefix_separator" {
  type        = string
  description = "The separator to use between the prefix and the generated timestamp for resource names"
  default     = "-"
}

variable "private_subnet_ids" {
  description = "List of private subnets Ids for the cluster and worker nodes"
  type        = list(string)
  default     = []
}

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

################################################################################
# Cluster
################################################################################

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = ""
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.22`)"
  default     = null
}

variable "cluster_enabled_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  default     = ["audit", "api", "authenticator"]
}

variable "cluster_additional_security_group_ids" {
  type        = list(string)
  description = "List of additional, externally created security group IDs to attach to the cluster control plane"
  default     = []
}

variable "control_plane_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned. Used for expanding the pool of subnets used by nodes/node groups without replacing the EKS control plane"
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs where the nodes/node groups will be provisioned. If `control_plane_subnet_ids` is not provided, the EKS cluster control plane (ENIs) will be provisioned in these subnets"
  default     = []
}

variable "cluster_endpoint_private_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  default     = false
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  default     = ["0.0.0.0/0"]
}

variable "cluster_ip_family" {
  type        = string
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created"
  default     = null
}

variable "cluster_service_ipv4_cidr" {
  type        = string
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  default     = null
}

variable "cluster_encryption_config" {
  type        = list(any)
  description = "Configuration block with encryption configuration for the cluster"
  default     = []
}

variable "attach_cluster_encryption_policy" {
  type        = bool
  description = "Indicates whether or not to attach an additional policy for the cluster IAM role to utilize the encryption key provided"
  default     = true
}

variable "cluster_tags" {
  type        = map(string)
  description = "A map of additional tags to add to the cluster"
  default     = {}
}

variable "create_cluster_primary_security_group_tags" {
  type        = bool
  description = "Indicates whether or not to tag the cluster's primary security group. This security group is created by the EKS service, not the module, and therefore tagging is handled after cluster creation"
  default     = true
}

variable "cluster_timeouts" {
  type        = map(string)
  description = "Create, update, and delete timeout configurations for the cluster"
  default     = {}
}


################################################################################
# CloudWatch Log Group
################################################################################

variable "create_cloudwatch_log_group" {
  type        = bool
  description = "Determines whether a log group is created by this module for the cluster logs. If not, AWS will automatically create one if logging is enabled"
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  type        = number
  description = "Number of days to retain log events. Default retention - 90 days"
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  type        = string
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  default     = null
}

################################################################################
# Cluster Security Group
################################################################################

variable "create_cluster_security_group" {
  type        = bool
  description = "Determines if a security group is created for the cluster or use the existing `cluster_security_group_id`"
  default     = true
}

variable "cluster_security_group_id" {
  type        = string
  description = "Existing security group ID to be attached to the cluster. Required if `create_cluster_security_group` = `false`"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC where the cluster and its nodes will be provisioned"
  default     = null
}

variable "cluster_security_group_name" {
  type        = string
  description = "Name to use on cluster security group created"
  default     = null
}

variable "cluster_security_group_use_name_prefix" {
  type        = bool
  description = "Determines whether cluster security group name (`cluster_security_group_name`) is used as a prefix"
  default     = true
}

variable "cluster_security_group_description" {
  type        = string
  description = "Description of the cluster security group created"
  default     = "EKS cluster security group"
}

variable "cluster_security_group_additional_rules" {
  type        = any
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  default     = {}
}

variable "cluster_security_group_tags" {
  type        = map(string)
  description = "A map of additional tags to add to the cluster security group created"
  default     = {}
}

################################################################################
# EKS IPV6 CNI Policy
################################################################################

variable "create_cni_ipv6_iam_policy" {
  type        = bool
  description = "Determines whether to create an [`AmazonEKS_CNI_IPv6_Policy`](https://docs.aws.amazon.com/eks/latest/userguide/cni-iam-role.html#cni-iam-role-create-ipv6-policy)"
  default     = false
}

################################################################################
# Node Security Group
################################################################################

variable "create_node_security_group" {
  type        = bool
  description = "Determines whether to create a security group for the node groups or use the existing `node_security_group_id`"
  default     = true
}

variable "node_security_group_id" {
  type        = string
  description = "ID of an existing security group to attach to the node groups created"
  default     = ""
}

variable "node_security_group_name" {
  type        = string
  description = "Name to use on node security group created"
  default     = null
}

variable "node_security_group_use_name_prefix" {
  type        = bool
  description = "Determines whether node security group name (`node_security_group_name`) is used as a prefix"
  default     = true
}

variable "node_security_group_description" {
  type        = string
  description = "Description of the node security group created"
  default     = "EKS node shared security group"
}

variable "node_security_group_additional_rules" {
  type        = any
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  default     = {}
}

variable "node_security_group_tags" {
  type        = map(string)
  description = "A map of additional tags to add to the node security group created"
  default     = {}
}

# TODO - at next breaking change, make 169.254.169.123/32 the default
variable "node_security_group_ntp_ipv4_cidr_block" {
  type        = list(string)
  description = "IPv4 CIDR block to allow NTP egress. Default is public IP space, but [Amazon Time Sync Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html) can be used as well with `[\"169.254.169.123/32\"]`"
  default     = ["0.0.0.0/0"]
}

# TODO - at next breaking change, make fd00:ec2::123/128 the default
variable "node_security_group_ntp_ipv6_cidr_block" {
  type        = list(string)
  description = "IPv4 CIDR block to allow NTP egress. Default is public IP space, but [Amazon Time Sync Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html) can be used as well with `[\"fd00:ec2::123/128\"]`"
  default     = ["::/0"]
}

################################################################################
# IRSA
################################################################################

variable "enable_irsa" {
  type        = bool
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  default     = true
}

variable "openid_connect_audiences" {
  type        = list(string)
  description = "List of OpenID Connect audience client IDs to add to the IRSA provider"
  default     = []
}

variable "custom_oidc_thumbprints" {
  type        = list(string)
  description = "Additional list of server certificate thumbprints for the OpenID Connect (OIDC) identity provider's server certificate(s)"
  default     = []
}

################################################################################
# Cluster IAM Role
################################################################################

variable "create_iam_role" {
  type        = bool
  description = "Determines whether a an IAM role is created or to use an existing IAM role"
  default     = true
}

variable "iam_role_arn" {
  type        = string
  description = "Existing IAM role ARN for the cluster. Required if `create_iam_role` is set to `false`"
  default     = null
}

variable "iam_role_name" {
  type        = string
  description = "Name to use on IAM role created"
  default     = null
}

variable "iam_role_use_name_prefix" {
  type        = bool
  description = "Determines whether the IAM role name (`iam_role_name`) is used as a prefix"
  default     = true
}

variable "iam_role_path" {
  type        = string
  description = "Cluster IAM role path"
  default     = null
}

variable "iam_role_description" {
  type        = string
  description = "Description of the role"
  default     = null
}

variable "iam_role_permissions_boundary" {
  type        = string
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  default     = null
}

variable "iam_role_additional_policies" {
  type        = list(string)
  description = "Additional policies to be added to the IAM role"
  default     = []
}

variable "iam_role_tags" {
  type        = map(string)
  description = "A map of additional tags to add to the IAM role created"
  default     = {}
}

variable "cluster_encryption_policy_use_name_prefix" {
  type        = bool
  description = "Determines whether cluster encryption policy name (`cluster_encryption_policy_name`) is used as a prefix"
  default     = true
}

variable "cluster_encryption_policy_name" {
  type        = string
  description = "Name to use on cluster encryption policy created"
  default     = null
}

variable "cluster_encryption_policy_description" {
  type        = string
  description = "Description of the cluster encryption policy created"
  default     = "Cluster encryption policy to allow cluster role to utilize CMK provided"
}

variable "cluster_encryption_policy_path" {
  type        = string
  description = "Cluster encryption policy path"
  default     = null
}

variable "cluster_encryption_policy_tags" {
  type        = map(string)
  description = "A map of additional tags to add to the cluster encryption policy created"
  default     = {}
}


################################################################################
# EKS Identity Provider
################################################################################

variable "cluster_identity_providers" {
  type        = any
  description = "Map of cluster identity provider configurations to enable for the cluster. Note - this is different/separate from IRSA"
  default     = {}
}

################################################################################
# KMS Key
################################################################################

variable "create_kms_key" {
  type        = bool
  description = "Controls if a KMS key for cluster encryption should be created"
  default     = false
}

variable "kms_key_arn" {
  type        = string
  description = "A KMS Key arn to provide as an input to the module."
  default     = ""
}

variable "cluster_kms_key_additional_admin_arns" {
  description = "A list of additional IAM ARNs that should have FULL access (kms:*) in the KMS key policy"
  type        = list(string)
  default     = []
}

variable "cluster_kms_key_arn" {
  description = "A valid EKS Cluster KMS Key ARN to encrypt Kubernetes secrets"
  type        = string
  default     = null
}