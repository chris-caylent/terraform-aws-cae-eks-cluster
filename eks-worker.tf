# ---------------------------------------------------------------------------------------------------------------------
# MANAGED NODE GROUPS
# ---------------------------------------------------------------------------------------------------------------------

module "eks_managed_node_group" {
  source = "./modules/managed-node-group"

  for_each = var.managed_node_groups

  managed_ng = each.value
  context    = local.node_group_context

  depends_on = [kubernetes_config_map.aws_auth]
}