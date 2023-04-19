# ---------------------------------------------------------------------------------------------------------------------
# HTTPS credentials secret -- Needed to connect ArgoCD to private git repositories (CodeCommit, for example)
# ---------------------------------------------------------------------------------------------------------------------

data "aws_secretsmanager_secret" "https_credential_secret" {
  for_each = { for k, v in var.applications : k => v if try(v.https_credential_secret, null) != null }
  name     = each.value.https_credential_secret
}

data "aws_secretsmanager_secret_version" "https_credential_secret_version" {
  for_each  = { for k, v in var.applications : k => v if try(v.https_credential_secret, null) != null }
  secret_id = data.aws_secretsmanager_secret.https_credential_secret[each.key].id
}
