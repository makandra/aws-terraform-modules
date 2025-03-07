data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "RDSOS_KMS" {
  #checkov:skip=CKV_AWS_109:This is required for a working KMS key policy
  #checkov:skip=CKV_AWS_111:This is required for a working KMS key policy
  #checkov:skip=CKV_AWS_356:Does not apply here because KMS key policies only apply to the key itself.
  count     = var.create_kms_key ? 1 : 0
  policy_id = "key-policy-cloudwatch"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com",
      ]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "RDSOS_KMS" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key to encrypt Cloudwatch loggroup for RDSOSMetrics (enhanced monitoring)."
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.RDSOS_KMS[0].json
}

resource "aws_kms_alias" "RDSOS_KMS" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/RDSOSMetrics"
  target_key_id = aws_kms_key.RDSOS_KMS[0].arn
}
