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
# ----------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "cross-account-dns-trust" {
  statement {
    sid    = "AllowCrossAccountDNSTrust"
    effect = "Allow"
    resources = [
      "arn:aws:iam::457368161226:role/dns-manager"
    ]
    actions = ["sts:AssumeRole"]
  }
}