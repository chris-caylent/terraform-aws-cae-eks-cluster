contact      = "cae-team@caylent.com"
region       = "us-west-2"
cluster_name = "terratest-eks-cluster"
environment  = "sbx"
team         = "caylent"
purpose      = "terratest"

workload = {
  path                    = "workload"
  target_revision         = "main"
  repo_url                = "https://helm-chart-repo.com"
  values                  = "environments/dev/values.yaml"
  namespace               = "workload-namespace"
  https_credential_secret = "argocd-git-repo-credentials"
  add_on_application      = false
}

service_accounts = {
  workload-sa = {
    namespace        = "workload-namespace"
    create_namespace = true
  }
}

platform_teams = {
  platform_admin = {
    users = [
      "arn:aws:iam::{accountID}:role/aws-reserved/sso.amazonaws.com/us-west-2/{platform_team_sso_role_arn_suffix}",
    ]
  }
  sre-admin = {
    users = [
      "arn:aws:iam::{accountID}:role/aws-reserved/sso.amazonaws.com/us-west-2/{sre_team_sso_role_arn_suffix}",
    ]
  }
}

# ArgoCD
argocd_cert_arn = "arn:aws:acm:us-west-2:${accountID}:certificate/${cert_id}"
argocd_values   = "argocd-dev-values.yaml"