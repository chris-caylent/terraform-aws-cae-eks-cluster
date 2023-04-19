contact      = "cae-team@caylent.com"
region       = "us-west-2"
cluster_name = "terratest-eks-cluster-with-core-addons"
environment  = "sbx"
team         = "caylent"
purpose      = "terratest"

dc_api_workload = {
  path                    = "workload"
  target_revision         = "main"
  repo_url                = "<helm-chart-url-here"
  values                  = "environments/development/values.yaml"
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

# ArgoCD
argocd_cert_arn = "arn:aws:acm:us-west-2:{accountID}:certificate/{certID}"
argocd_values = "argocd-development-values.yaml"