# Helm AddOn

## Introduction

Helm Addon module can be used to provision a generic Helm Chart as an Add-On for an EKS cluster. This module does the following:

1. Create an IAM role for Service Accounts with the provided configuration for the [`irsa`](../../irsa/) module.
2. If `manage_via_gitops` is set to `false`, provision the helm chart for the add-on based on the configuration provided for the `helm_config` as defined in the [helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs) documentation.
