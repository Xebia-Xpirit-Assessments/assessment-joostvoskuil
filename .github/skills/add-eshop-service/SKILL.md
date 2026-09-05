---
name: add-eshop-service
description: 'Add a deployable eShop service safely. Use when creating an HTTP API, background worker, web application, or internal service; updating AppHost, Docker, Azure deployment, CI mappings, or service-specific tests.'
argument-hint: 'Service name, service type, dependencies, and whether it is public or internal'
user-invocable: true
---

# Add an eShop service

Use this workflow when a new deployable component must participate in local Aspire orchestration, CI, and Azure delivery. Keep the change additive and preserve service boundaries; do not put service-specific behavior in `eShop.ServiceDefaults` merely to reuse it.

## 1. Define the service contract

Before creating files, document the following in the change or issue:

- The service type: HTTP API, background worker, public web application, or internal service.
- Its owning bounded context, data ownership, and external contract.
- Dependencies: database, Redis, RabbitMQ, HTTP/gRPC services, and Identity callbacks.
- Whether external ingress is required. Only WebApp and Identity.API are public by default; choose internal ingress unless a reviewed requirement says otherwise.
- The nearest existing service that provides the implementation pattern.

Do not give the service direct access to another service's persistence. Use its API or an integration event.

## 2. Implement the service boundary

1. Create the project using the nearest matching project as the template.
2. Compose startup from `AddServiceDefaults()`, the service's `AddApplicationServices()`, service routes/workers, and `MapDefaultEndpoints()` as applicable.
3. Keep service-specific registrations in `Extensions/Extensions.cs`.
4. Add domain behavior and persistence only in the owning domain/infrastructure projects.
5. Add focused tests using the repository's established test framework:
   - MSTest and NSubstitute for isolated unit behavior.
   - xUnit with an Aspire fixture for HTTP functional behavior.
   - Playwright only for user-visible WebApp flows.

Use the repository instructions for Minimal API, idempotency, logging, and integration-event conventions. They are always-on standards, not copied into this skill.

## 3. Wire local Aspire composition

Update `src/eShop.AppHost/Program.cs`:

1. Add the project using its stable service-discovery name.
2. Add `.WithReference(...)` for every owned resource or service dependency.
3. Use `.WithEnvironment(...)` only for configuration values that must be supplied explicitly, such as Identity endpoints or callback URLs.
4. Add an external HTTP endpoint only when the service must be reached from outside Aspire.
5. Update Identity callback configuration when the service participates in sign-in/sign-out redirect flows.

Use [the Aspire composition skill](../eshop-aspire-composition/SKILL.md) for endpoint, resource-reference, or local orchestration details.

## 4. Add delivery integration

A deployable application service must be represented consistently in all delivery mappings:

- Root `azure.yaml` service definition.
- `infra/azd/main.bicep`, preserving its existing-resource image pattern for every sibling service.
- A Dockerfile and a valid repository-root Docker build context.
- `.github/workflows/ci.yml` change detection.
- `.github/workflows/template-build-service.yml` service-to-project, Dockerfile, and test mappings.
- `.github/workflows/template-deploy-service.yml` service-to-image-repository and Container App mappings.
- A service deployment caller workflow when this repository deploys it separately.

Use the infrastructure and GitHub Actions skills for Bicep, OIDC, image tagging, GitHub Environments, and action pinning. Do not expose backing services publicly or hard-code Azure identifiers/secrets.

## 5. Validate in layers

1. Run the closest unit or functional test project.
2. Build the service project and its Docker image.
3. Run affected functional tests when an HTTP contract, database, messaging, or shared service changed.
4. Run Playwright for affected WebApp/authentication flows.
5. Compile the Bicep entry points and validate changed workflows.
6. Confirm the CI path filters select the new service for its source, test, shared dependency, and infrastructure changes.

Report exact commands and whether a failure is an assertion, build error, missing workload, Docker issue, or unavailable credentials.

## Completion checklist

- [ ] A single bounded context owns the service's data and business invariants.
- [ ] AppHost resource references and external ingress are intentional.
- [ ] The service has focused, framework-appropriate tests.
- [ ] CI detects and validates source changes for the service.
- [ ] Azure service, Bicep, Docker, and deployment mappings agree on the service name.
- [ ] No credentials, connection strings, or generated deployment state were committed.
