# eShop Azure deployment

This folder deploys the minimal eShop shopping slice with **Bicep** and **GitHub Actions**. It intentionally does not use `azd` or Azure DevOps.

## Environments and CAF names

Staging and Production use the same Azure subscription but are isolated in distinct resource groups:

| Environment | CAF code | Resource group | Container registry |
| --- | --- | --- | --- |
| Staging | `stg` | `rg-eshop-stg-swe-001` | `acreshopstgswe001` |
| Production | `prd` | `rg-eshop-prd-swe-001` | `acreshopprdswe001` |

Deployments use the Sweden Central Azure region (`swedencentral`) and the CAF region code `swe`. Names follow the Azure CAF pattern `<resource-abbreviation>-<workload>-<environment>-<region>-<instance>`. Examples include `cae-eshop-stg-swe-001` for the Container Apps environment and `ca-eshop-web-prd-swe-001` for the Production web app. Azure Container Registry names use the same components without separators because ACR permits alphanumeric characters only; registry names must also be globally unique.

## Architecture

Each environment creates its own low-cost resources:

- ACR Basic (`acr`)
- Container Apps Consumption environment (`cae`)
- Log Analytics workspace (`log`)
- PostgreSQL Flexible Server, Burstable `Standard_B1ms`, no high availability (`psql`)
- Azure Cache for Redis Basic C0 (`redis`)
- Internal RabbitMQ Container App (demo-only)
- Public WebApp and Identity API Container Apps
- Internal Basket, Catalog, and Ordering API Container Apps

The application images use immutable full Git commit SHA tags. Staging builds and publishes images to its own registry. Production checks out the same SHA and rebuilds it into the Production registry, so its deployed source is immutable and auditable without granting either environment access to the other's registry.

## GitHub configuration

Create two GitHub Environments named exactly `staging` and `production`. Store these secrets separately in **each** Environment:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `POSTGRES_ADMINISTRATOR_PASSWORD`
- `RABBITMQ_PASSWORD`

The three `AZURE_*` values are intentionally Environment secrets, even though both environments use the same subscription ID. Use separate Entra application registrations or managed identities for Staging and Production so each can receive narrowly-scoped permissions.

Configure an Entra federated credential for each identity with the GitHub repository subject matching its Environment:

- `repo:Xebia-Xpirit-Assessments/assessment-joostvoskuil:environment:staging`
- `repo:Xebia-Xpirit-Assessments/assessment-joostvoskuil:environment:production`

Grant each identity deployment rights only over its corresponding resource group. The identity also needs `AcrPush` on its environment registry to publish images. Do not use an Azure client secret, publish profile, registry admin account, or subscription-wide Owner role.

Protect the `production` GitHub Environment with required reviewers. Every push to `main`, or manual dispatch, follows the fixed Staging → Production promotion flow. Production proceeds only after Staging succeeds and its required Environment approval is granted. A manual dispatch may provide a complete immutable commit SHA; otherwise the dispatched revision is used.

## Nightly cost cleanup

`.github/workflows/purge-test-environments.yml` deletes both test resource groups every night at 02:00 UTC:

- `rg-eshop-stg-swe-001`
- `rg-eshop-prd-swe-001`

The workflow uses the `staging` and `production` GitHub Environments independently, so each Azure identity needs delete permission only on its own resource group. It uses OIDC and waits for each deletion to finish. The workflow can also be started manually from the Actions tab. This is intentionally destructive and is appropriate only because these Azure environments are test setup; do not reuse it for real production workloads. Re-running the deployment workflow recreates the required resources.

## Deployment flow

1. CI runs for pull requests to `main` and builds the .NET web solution and Bicep templates without Azure credentials.
2. A push to `main` invokes the reusable CD workflow for Staging.
3. CD signs in with GitHub OIDC, creates/updates the Staging resource group and ACR, builds SHA-tagged container images, runs Bicep `what-if`, then deploys the Container Apps environment.
4. After Staging succeeds, the protected Production job requests approval and then deploys the same immutable SHA using only the Production Environment’s secrets and resource group.

`bootstrap.bicep` is subscription-scoped and creates only the supplied environment resource group and ACR. `main.bicep` is resource-group-scoped and creates all environment resources. This prevents a Staging run from changing Production resources.

## Local validation

Compile the templates before opening a pull request:

```text
az bicep build --file infra/bootstrap.bicep
az bicep build --file infra/main.bicep
```

The workflow runs `az deployment group what-if` before applying the environment deployment. Never provide deployment secrets through checked-in Bicep parameter files.

## Demo limitations

This is a cost-optimized proof of concept, **not production-ready infrastructure**. It deliberately omits private networking, Key Vault, a managed RabbitMQ offering, high availability, zone redundancy, production IdentityServer key management, and a controlled migration job. PostgreSQL permits Azure-service access so Container Apps can reach the low-cost public endpoint; replace this with private networking before handling production data. The existing application applies database migrations at startup and uses a development signing credential—both must be replaced for a real production rollout.
