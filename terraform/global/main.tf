################################################################################
# GLOBAL / SHARED LAYER
# - Remote state bucket (S3 native locking, no DynamoDB needed on TF >= 1.10)
# - GitHub Actions OIDC provider + least-privilege roles
# - Shared ECR repositories (images are built once and promoted dev -> prod)
################################################################################

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "${var.project}-tfstate-${local.account_id}"
}

# ------------------------------------------------------------------------------
# Terraform remote state bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "tfstate_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate_tls_only.json
}

# ------------------------------------------------------------------------------
# Shared ECR repositories
# ------------------------------------------------------------------------------
module "ecr" {
  source       = "../modules/ecr"
  project      = var.project
  repositories = var.ecr_repositories
}

# ------------------------------------------------------------------------------
# GitHub Actions OIDC federation + roles
# ------------------------------------------------------------------------------
module "github_oidc" {
  source = "../modules/github-oidc"

  project            = var.project
  github_org         = var.github_org
  github_repo        = var.github_repo
  environments       = var.environments
  state_bucket_arn   = aws_s3_bucket.tfstate.arn
  ecr_repository_arn = values(module.ecr.repository_arns)
}
