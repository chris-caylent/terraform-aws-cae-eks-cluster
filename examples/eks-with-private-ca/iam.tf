resource "aws_iam_policy" "cert-manager-cross-account" {
  description = "cert-manager cross account IAM policy."
  name        = "cert-manager-cross-account"
  policy      = data.aws_iam_policy_document.cross-account-dns-trust.json
#   tags        = var.addon_context.tags
}