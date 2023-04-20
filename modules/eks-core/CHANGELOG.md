# Changelog

[//]: # (Breaking Changes, then Notes, then Features, then Improvements, then Bug Fixes)

## 1.0.0

Notes:

- Only managed [node types](https://docs.aws.amazon.com/eks/latest/userguide/eks-compute.html) are supported:
  - [EKS Managed Node Group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)

Features:

- Support for Amazon Linux 2 EKS Optimized AMI.
- Support for module created security group, bring your own security groups, as well as adding additional security group rules to the module created security group(s).
- Support for creating node groups/profiles separate from the cluster through the use of sub-modules (this is done in the EKS-Cluster module)
- Support for Node security groups
- AWS EKS Identity Provider Configuration
- Support for CloudWatch Log groups
- Support for cluster encryption via KMS
- Support for IAM role creation, trust policies, and assumeroles
