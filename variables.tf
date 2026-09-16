variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "tech-challenge"
}

variable "app_backend_host" {
  description = "host:port of the app's LoadBalancer Service (Repo 4, k8s/03-app/service.yaml) — copied manually from `kubectl get svc workshop-app -n workshop` after Repo 4's deploy-aws.yml runs, no scheme/path. Same manual-copy pattern already used for the RDS endpoint between Repos 3 and 4."
  type        = string
}
