#!/usr/bin/env bash
# Prints, as one line of JSON, the value of Terraform's `service_hosts` variable:
# the load balancer host of each service, read from the cluster that kubectl
# points to.
#
#   scripts/discover-service-hosts.sh [plan|apply|destroy]
#
# terraform-apply.yml runs it after `aws eks update-kubeconfig` and hands the
# result to Terraform through TF_VAR_service_hosts, so nobody copies four hosts
# by hand at the start of every Lab session.
#
# A service that is not deployed (or whose load balancer has no host yet) makes
# the script fail, naming each one, instead of routing the gateway to nothing.
# For `destroy` the values do not matter, and the services are often already
# gone, so placeholders are printed and the cluster is not even queried.
set -euo pipefail

ACTION=${1:-apply}

# key in service_hosts | namespace | Service name (see each service's k8s/ manifests)
SERVICES=(
  "os|workshop|workshop-app"
  "inventory|inventory|inventory-service"
  "billing|billing|billing-service"
  "execution|execution|execution-service"
)

if [[ $ACTION == destroy ]]; then
  jq -nc '{os: "unused.invalid", inventory: "unused.invalid", billing: "unused.invalid", execution: "unused.invalid"}'
  exit 0
fi

hosts='{}'
missing=()
for spec in "${SERVICES[@]}"; do
  IFS='|' read -r key namespace service <<<"$spec"
  host=$(kubectl get svc "$service" -n "$namespace" \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [[ -z $host ]]; then
    missing+=("${key}: Service ${service} in namespace ${namespace}")
    continue
  fi
  hosts=$(jq -c --arg key "$key" --arg host "$host" '. + {($key): $host}' <<<"$hosts")
done

if ((${#missing[@]} > 0)); then
  {
    echo "No load balancer host found for:"
    printf '  - %s\n' "${missing[@]}"
    echo "Deploy these services first (their deploy-aws.yml) and wait for the load balancer."
  } >&2
  exit 1
fi

printf '%s\n' "$hosts"
