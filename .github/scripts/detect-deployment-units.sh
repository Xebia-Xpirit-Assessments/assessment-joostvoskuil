#!/usr/bin/env bash
set -euo pipefail

base_ref="${1:-}"
head_ref="${2:-HEAD}"
target="${3:-auto}"

services=(webapp identity-api basket-api catalog-api ordering-api)
changed=()

if [[ "$target" == "all" ]]; then
  changed=("${services[@]}")
  infra=true
elif [[ "$target" == "infrastructure" ]]; then
  infra=true
elif [[ "$target" != "auto" && " ${services[*]} " == *" $target "* ]]; then
  changed=("$target")
  infra=false
else
  infra=false
  files=()
  if [[ -n "$base_ref" && "$base_ref" != "0000000000000000000000000000000000000000" ]] && git cat-file -e "$base_ref^{commit}" 2>/dev/null; then
    while IFS= read -r file; do files+=("$file"); done < <(git diff --name-only "$base_ref" "$head_ref")
  else
    while IFS= read -r file; do files+=("$file"); done < <(git ls-tree -r --name-only "$head_ref")
  fi

  for file in "${files[@]}"; do
    case "$file" in
      infra/bootstrap.bicep|infra/main.bicep|infra/modules/*|infra/application.bicep)
        infra=true ;;
    esac

    case "$file" in
      src/WebApp/*|src/WebAppComponents/*) changed+=(webapp) ;;
      src/Identity.API/*) changed+=(identity-api) ;;
      src/Basket.API/*) changed+=(basket-api) ;;
      src/Catalog.API/*) changed+=(catalog-api) ;;
      src/Ordering.API/*|src/Ordering.Domain/*|src/Ordering.Infrastructure/*) changed+=(ordering-api) ;;
      src/eShop.ServiceDefaults/*)
        changed+=(webapp identity-api basket-api catalog-api ordering-api) ;;
      src/EventBus/*|src/EventBusRabbitMQ/*)
        changed+=(webapp basket-api catalog-api ordering-api) ;;
      src/IntegrationEventLogEF/*)
        changed+=(catalog-api ordering-api) ;;
      Directory.Build.props|Directory.Build.targets|Directory.Packages.props|global.json|nuget.config|.dockerignore)
        changed+=(webapp identity-api basket-api catalog-api ordering-api) ;;
      .github/actions/build-push-image/*|.github/workflows/deploy*.yml|.github/scripts/detect-deployment-units.sh)
        changed+=(webapp identity-api basket-api catalog-api ordering-api) ;;
    esac
  done
fi

if [[ "$infra" == true && ${#changed[@]} -eq 0 && "$target" == "auto" ]]; then
  # Shared infrastructure changes do not implicitly rebuild application images.
  :
fi

selected=()
while IFS= read -r service; do selected+=("$service"); done < <(printf '%s\n' "${changed[@]-}" | awk 'NF' | sort -u)
services_json='{"include":[]}'
if ((${#selected[@]} > 0)); then
  entries=()
  for service in "${selected[@]}"; do
    entries+=("{\"service\":\"$service\"}")
  done
  joined=$(IFS=,; echo "${entries[*]}")
  services_json="{\"include\":[$joined]}"
fi

printf 'infra=%s\n' "$infra" >> "${GITHUB_OUTPUT:-/dev/stdout}"
printf 'services=%s\n' "$services_json" >> "${GITHUB_OUTPUT:-/dev/stdout}"
printf 'summary=infra=%s services=%s\n' "$infra" "${selected[*]:-none}" >> "${GITHUB_OUTPUT:-/dev/stdout}"
