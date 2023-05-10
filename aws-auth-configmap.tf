# kubernetes_config_map will fail because the configmap already exists
resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.create_eks ? 1 : 0
  # By using force, we overwrite the keys
  force = true
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = merge(
      {
        "app.kubernetes.io/managed-by" = "platform-team"
        "app.kubernetes.io/created-by" = "platform-team"
      },
      var.aws_auth_additional_labels
    )
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.managed_node_group_aws_auth_config_map,
        local.application_teams_config_map,
        local.platform_teams_config_map,
        var.map_roles,
      ))
    )
    mapUsers    = yamlencode(var.map_users)
    mapAccounts = yamlencode(var.map_accounts)
  }

  depends_on = [module.eks_core.cluster_id, data.http.eks_cluster_readiness[0]]
}