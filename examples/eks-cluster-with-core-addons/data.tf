# ------------------------------------------------------------------------------------
# This creates a IAM Policy content limiting access to the secret in Secrets Manager
# if this policy is used in every environment or account
# ------------------------------------------------------------------------------------

data "aws_iam_policy_document" "secrets_management_ro_policy" {
  statement {
    sid    = "AllowReadOnly"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
  }
}