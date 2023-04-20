# ------------------------------------------------------------------------------------
# This creates a IAM Policy content limiting access to the secret in Secrets Manager
# if this policy is used in every environment or account
# ------------------------------------------------------------------------------------

data "aws_iam_policy_document" "secrets_management_ro_policy" {
  statement {
    sid    = "AllowReadOnlySecretsKMS"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
  }
}

# ----------------------------------------------------------------------------------------------
# Cert-manager Trust policy for cross account access (role must exists in the other account 1st)
# configuration below is used to place a role in the current account with permissions to assume a
# dns manager role in a different account like a networking or shared services account that
# managers dns records and zones
# ----------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "cross-account-dns-trust" {
  statement {
    sid    = "AllowCrossAccountDNSTrust"
    effect = "Allow"
    resources = [
      "arn:aws:iam::${crossAccountId}:role/dns-manager"
    ]
    actions = ["sts:AssumeRole"]
  }
}