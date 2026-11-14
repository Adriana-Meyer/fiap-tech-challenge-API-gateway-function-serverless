variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "tech-challenge"
}

variable "service_hosts" {
  description = <<-EOT
    host (and optional port) of the LoadBalancer Service of each service, with no scheme and no path,
    for example "a1b2c3.elb.us-east-1.amazonaws.com". The Services are the ones the services' own
    deploy-aws.yml create (workshop-app in `workshop`, inventory-service in `inventory`,
    billing-service in `billing`, execution-service in `execution`).

    terraform-apply.yml fills this in by itself (scripts/discover-service-hosts.sh); to run Terraform
    by hand, pass it as JSON in TF_VAR_service_hosts.
  EOT
  type = object({
    os        = string
    inventory = string
    billing   = string
    execution = string
  })

  validation {
    condition     = alltrue([for host in values(var.service_hosts) : can(regex("^[A-Za-z0-9.-]+(:[0-9]+)?$", host))])
    error_message = "Each service host must be a host name with an optional port, with no scheme (http://) and no path."
  }
}
