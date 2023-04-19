contact      = "cae-team@caylent.com"
region       = "us-west-2"
cluster_name = "terratest-eks-cluster-with-private-ca"
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
  # dc-api-terratest = {
  #   namespace        = "dc-api"
  #   create_namespace = true
  # }
}

# ArgoCD
argocd_cert_arn = "arn:aws:acm:us-west-2:XXXXXXXXXXX:certificate/43122ea8-e955-432c-90f6-22c77ce36e4c"
argocd_values = "argocd-values.yaml"