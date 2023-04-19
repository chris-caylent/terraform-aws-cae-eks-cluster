locals {
  name = "splunk"
}

module "helm_addon" {
  source = "../helm-addon"

  helm_config = merge(
    {
      name             = local.name
      chart            = local.name
      repository       = "https://splunk.github.io/splunk-connect-for-kubernetes/"
      version          = "1.5.2"
      namespace        = local.name
      create_namespace = true
      description      = "Splunk Kubernetes Logging"
    },
    var.helm_config
  )
  manage_via_gitops = var.manage_via_gitops

  addon_context = var.addon_context
}
