project         = "aiml"
environment     = "dev"
region          = "us-east-1"
gitops_repo_url = "https://github.com/Cloud-Deployment-Resources-asimshahibm/devops-series-ai-ml-workload-deployment.git"
gitops_revision = "main"

vpc_cidr           = "10.10.0.0/16"
single_nat_gateway = true # cost-optimised dev

kubernetes_version = "1.33"

# Your admin role (scripts/configure.sh fills this from `aws sts get-caller-identity`)
cluster_admin_principal_arns = ["__ADMIN_ROLE_ARN__"]

system_node_group = {
  instance_types = ["m6i.large"]
  min_size       = 2
  max_size       = 3
  desired_size   = 2
}

rds = {
  instance_class        = "db.t4g.medium"
  multi_az              = false
  deletion_protection   = false
  backup_retention_days = 3
}

argocd_ha = false
