---
name: infra-deployment-standards
description: "Standards for Azure infrastructure deployments and Bicep in this repository. Use when creating, reviewing, validating, or changing Bicep, Azure resources, Container Apps, GitHub Actions deployments, environment configuration, CAF naming, OIDC authentication, or infrastructure documentation."
user-invocable: true
---

# Infrastructure deployment and Bicep standards

Use this skill for all Azure infrastructure and deployment changes in this repository. The deployment platform is Azure, but the delivery platform is GitHub Actions. Do not introduce Azure DevOps pipelines or `azd` unless the requirements explicitly change.

## Repository deployment model

- Infrastructure is written in Bicep under `infra/`.
- Reusable resource definitions belong under `infra/modules/`.
- `infra/bootstrap.bicep` is subscription-scoped and may create only the selected environment's resource group and bootstrap resources.
- `infra/main.bicep` is resource-group-scoped and deploys resources inside one environment resource group.
- GitHub Actions owns source checkout, validation, image publication, orchestration, and deployment.
- Local .NET Aspire remains the local composition model; do not change `src/eShop.AppHost/Program.cs` into the Azure deployment mechanism.
- Preserve service boundaries. Do not move application or persistence responsibilities into infrastructure code.

## Environment isolation

There are two environments in the same Azure subscription:

| Environment | CAF code | GitHub Environment | Resource group         |
| ----------- | -------- | ------------------ | ---------------------- |
| Staging     | `stg`    | `staging`          | `rg-eshop-stg-weu-001` |
| Production  | `prd`    | `production`       | `rg-eshop-prd-weu-001` |

Rules:

- Every deployment must receive an explicit environment and resource group.
- Staging and Production must use separate resource groups, Container Apps environments, registries, databases, caches, and messaging resources.
- A Staging deployment must not reference, modify, or grant access to Production resources.
- A Production deployment must not depend on a mutable Staging resource.
- Use the same reusable Bicep modules for both environments with different parameters.
- Production must be promoted using an immutable image tag that has already been validated in Staging.
- Production deployments require a protected GitHub Environment and manual approval.
- Pushes to `main` may deploy Staging automatically; they must not deploy Production automatically without an explicitly approved policy.

## CAF naming

Use the Azure Cloud Adoption Framework naming pattern:

`<resource-abbreviation>-<workload>-<environment>-<region>-<instance>`

For this repository:

- Workload: `eshop`
- Environment: `stg` or `prd`
- Region: `weu` by default, but keep it parameterized
- Instance: `001`

Examples:

- `rg-eshop-stg-weu-001`
- `cae-eshop-stg-weu-001`
- `ca-eshop-web-stg-weu-001`
- `psql-eshop-stg-weu-001`
- `redis-eshop-stg-weu-001`
- `log-eshop-stg-weu-001`

Important naming rules:

- Keep naming inputs parameterized; do not scatter literal names across modules.
- Use resource-specific CAF abbreviations.
- Respect Azure resource naming restrictions. For example, ACR names must be globally unique and alphanumeric, so `acreshopstgweu001` is valid while `acr-eshop-stg-weu-001` is not.
- Use a deterministic instance number rather than random names unless uniqueness is an explicit requirement.
- Keep names stable across updates so Bicep updates resources instead of replacing them.
- Validate length, character, and global uniqueness constraints before deployment.

## Bicep module design

- Keep `main.bicep` an orchestration/composition file, not a large resource dump.
- Create one focused module per independently managed concern, such as:
  - `acr.bicep`
  - `container-app-environment.bicep`
  - `container-app.bicep`
  - `postgres.bicep`
  - `redis.bicep`
  - `rabbitmq.bicep`
- Modules must have explicit parameters and outputs.
- Prefer parameters for location, environment code, region code, instance, SKU, image tag, and sizing.
- Use module outputs instead of reconstructing resource properties in multiple places.
- Use `existing` resources only when the resource is intentionally owned outside the current deployment.
- Do not create subscription-wide resources from a resource-group-scoped template.
- Use `dependsOn` only where implicit dependencies cannot express the relationship.
- Use stable `guid()` values for role assignment names.
- Use `@secure()` on string or object secret parameters. Never commit passwords, tokens, connection strings, or generated parameter files containing secrets.
- Do not use secure decorators on array parameters; Bicep does not support that target type.
- Do not make secure parameters default to real values. Empty/default-free secure parameters are preferred.
- Keep generated Bicep JSON output out of source control; compile with `--stdout` in CI where practical.

## Required low-cost architecture

The current minimal deployment consists of:

- Azure Container Apps Consumption
- Azure Container Registry Basic
- Azure Database for PostgreSQL Flexible Server, Burstable and no HA
- Azure Cache for Redis Basic C0
- Internal RabbitMQ Container App for the proof of concept
- Log Analytics with short retention as required by Container Apps
- Five application Container Apps:
  - `WebApp`
  - `Identity.API`
  - `Basket.API`
  - `Catalog.API`
  - `Ordering.API`

Ingress rules:

- Public ingress: `WebApp` and `Identity.API` only.
- Internal ingress: Basket, Catalog, Ordering, and RabbitMQ.
- Never expose databases, Redis, or RabbitMQ publicly unless a reviewed requirement explicitly requires it.
- Use HTTP/2 or the protocol required by the service contract for gRPC services.

This architecture is cost-optimized for a demonstration, not a production recommendation. If production requirements change, reassess private networking, managed messaging, Key Vault, HA, zone redundancy, and migration orchestration rather than silently weakening the boundary.

## Secrets and identity

GitHub Actions must authenticate to Azure using OIDC only:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These values are supplied as secrets in both GitHub Environments:

- `staging`
- `production`

Rules:

- Never use a client secret, certificate, publish profile, or registry admin password in GitHub Actions.
- Grant each environment identity access only to its own resource group and registry.
- Grant `AcrPush` only on the target environment's registry.
- Use managed identities for Azure-hosted workloads whenever the service supports it.
- Do not print secrets in workflow logs, Bicep outputs, CLI command output, or diagnostic messages.
- Avoid passing secrets as command-line arguments when a safer supported input mechanism exists; if the Azure CLI requires a parameter, ensure logs and shell tracing cannot reveal it.
- Do not put secrets in `.bicepparam`, JSON, YAML, Dockerfiles, or committed `.env` files.
- Local `.env` files must remain ignored by Git.

## Application configuration contract

Infrastructure must provide configuration using the names already consumed by the applications. Do not invent a second configuration convention without changing and testing the application.

Expected categories include:

- `ConnectionStrings__catalogdb`
- `ConnectionStrings__identitydb`
- `ConnectionStrings__orderingdb`
- `ConnectionStrings__Redis`
- `ConnectionStrings__EventBus`
- `IdentityUrl`
- `CallBackUrl`
- Internal service endpoints for `basket-api`, `catalog-api`, and `ordering-api`

Keep local Aspire service names and Azure internal DNS mappings aligned with the existing service clients. Preserve the WebApp-to-Identity callback and redirect URI contract.

## GitHub Actions standards

Organize workflows into these layers:

1. CI workflow for pull requests targeting `main`.
2. Reusable CD workflow accepting explicit environment and deployment inputs.
3. Orchestration workflow that deploys Staging automatically and promotes Production manually.
4. Composite actions for repeated build, publish, or validation logic.

Every remote `uses:` reference must:

- Use a complete 40-character commit SHA.
- Include an inline human-readable release comment.
- Be reviewed deliberately when updated.

Workflow permissions:

- Default to `contents: read`.
- Add `id-token: write` only to jobs that authenticate to Azure.
- Keep Azure deployment permissions separate from CI.
- Use GitHub Environment-scoped secrets and protection rules.
- Do not hard-code subscription IDs, tenant IDs, client IDs, passwords, or environment secrets in workflow files.

Artifact rules:

- Build and publish images with immutable full commit SHA tags.
- Production should consume the selected immutable tag, not `latest`.
- Do not deploy an image before CI and Staging validation for the Production promotion path.
- Keep registry and environment selection explicit in reusable workflow inputs.

## Validation gates

Before merging infrastructure or workflow changes:

1. Compile every Bicep entry point:
   - `az bicep build --file infra/bootstrap.bicep --stdout`
   - `az bicep build --file infra/main.bicep --stdout`
2. Resolve all errors and review warnings; do not treat a successful command as proof that the design is safe.
3. Run Bicep linting or the available equivalent.
4. Validate GitHub Actions YAML with `actionlint` when available.
5. Confirm all remote actions are full SHA pins.
6. Run `git diff --check`.
7. Build the affected Docker images and verify the expected listening ports.
8. Run the repository-approved .NET build and focused tests using the .NET 8 SDK.
9. Review the deployment what-if before applying changes in Azure.
10. Verify the target resource group and environment before any deployment command.
11. After deployment, smoke-test the intended public endpoint and confirm internal-only resources have no public ingress.

For destructive or potentially disruptive changes:

- Show the planned impact.
- Require explicit user confirmation before deployment.
- Never hide deletion or replacement behind a generic deployment command.
- Prefer incremental, additive changes for existing environments.

## Review checklist

### Naming and scope

- [ ] Environment is explicitly `staging` or `production`.
- [ ] Resource group is the matching CAF-named group.
- [ ] All resource names use CAF abbreviations and stable parameters.
- [ ] Resources cannot accidentally cross environment boundaries.

### Bicep

- [ ] Entry points have the correct deployment scope.
- [ ] Repeated resource patterns use modules.
- [ ] Parameters and outputs are explicit.
- [ ] Secrets use secure string/object parameters and are not committed.
- [ ] No generated JSON or deployment artifacts are committed.
- [ ] Bicep compiles without errors and warnings are understood.

### Security

- [ ] GitHub Actions uses OIDC.
- [ ] Azure IDs come from the selected GitHub Environment.
- [ ] No long-lived credentials or registry admin account are used.
- [ ] RBAC is scoped to the target resource group/resource.
- [ ] Only intended public ingress is enabled.
- [ ] TLS 1.2 or newer is used where supported.

### Delivery

- [ ] CI is separate from CD.
- [ ] CD is reusable and receives explicit environment inputs.
- [ ] Staging is automatic only where intended.
- [ ] Production has a manual approval gate.
- [ ] Images use immutable commit SHA tags.
- [ ] `what-if` is reviewed before apply.
- [ ] Deployment outputs are captured without parsing log text.

### Documentation

- [ ] New Azure resources and parameters are documented.
- [ ] Required GitHub Environment secrets are documented by name, never by value.
- [ ] OIDC federated credential subjects and RBAC scope are documented.
- [ ] Demo-only limitations and production hardening gaps are explicit.
- [ ] Teardown and rollback considerations are documented.
