variable "region" {
  description = "AWS region for shared resources (state bucket, ECR)."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Short project prefix used in every resource name."
  type        = string
  default     = "aiml"
}

variable "github_org" {
  description = "GitHub organization or user that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org)."
  type        = string
}

variable "ecr_repositories" {
  description = "Container repositories shared by all environments (build once, promote everywhere)."
  type        = list(string)
  default     = ["ml-inference", "ml-training", "ml-ray"]
}

variable "environments" {
  description = "Environments whose GitHub Environment may assume the apply role."
  type        = list(string)
  default     = ["dev", "prod"]
}
