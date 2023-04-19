# [CoreDNS](https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html)

This addons supports managing CoreDNS through the EKS managed addon via Helm.

## EKS Managed CoreDNS Addon

To enable and modify the EKS managed addon for CoreDNS, you can reference the following configuration and tailor to suit:

```hcl
  enable_amazon_eks_coredns = true
  amazon_eks_coredns_config = {
    most_recent        = true
    kubernetes_version = "1.21"
    resolve_conflicts  = "OVERWRITE"
    ...
  }
```

## Removing Default CoreDNS Deployment

Setting `remove_default_coredns_deployment = true` will remove the default CoreDNS deployment provided by EKS and update the labels and and annotations for kube-dns to allow Helm to manage it. These changes will allow for CoreDNS to be deployed via a Helm chart into a cluster either through self-managed addon (`enable_self_managed_coredns = true`) or some other means (i.e. - GitOps approach).

```hcl
  remove_default_coredns_deployment = true
```

# CoreDNS [Cluster Proportional Autoscaler](https://github.com/kubernetes-sigs/cluster-proportional-autoscaler)

By default, EKS provisions CoreDNS with a replica count of 2. As the cluster size increases and more traffic is flowing through the cluster, it is recommended to scale CoreDNS to meet this demand. The cluster proportional autoscaler is recommended to scale the CoreDNS deployment and therefore is provided by default when enabling CoreDNS. A set of default settings for scaling CoreDNS is provided but users can provide their own settings as well to override the defaults via `cluster_proportional_autoscaler_helm_config = {}`. In addition, users have the ability to opt out of this default enablement and either not use the cluster proportional autoscaler for CoreDNS or provide a separate implementation of cluster proportional autoscaler.

```hcl
  enable_cluster_proportional_autoscaler      = true
  cluster_proportional_autoscaler_helm_config = { ... }
```
