---
name: eshop-aspire-composition
description: 'Change local .NET Aspire composition for eShop. Use when editing eShop.AppHost, adding services or resources, binding databases, Redis, RabbitMQ, endpoints, callback URLs, service discovery, or diagnosing local orchestration.'
argument-hint: 'Service/resource change or local orchestration problem'
user-invocable: true
---

# Compose eShop locally with Aspire

`src/eShop.AppHost/Program.cs` is the local composition root. Use this skill for local orchestration only; it does not replace the Azure Bicep deployment model.

## Establish the intended topology

1. Identify the component type: API, worker, reverse proxy, or UI.
2. Identify its owned state and upstream/downstream dependencies.
3. Decide whether it needs a public endpoint. Public exposure is explicit through `.WithExternalHttpEndpoints()`.
4. Identify configuration values that cannot be inferred from a resource reference, especially callback and Identity URLs.
5. Keep the service's DI registrations inside its own `Extensions/Extensions.cs`; AppHost declares relationships, not application behavior.

## Follow the established composition patterns

- Reuse the existing shared local resources: PostgreSQL (`postgres`), Redis (`redis`), and RabbitMQ (`eventbus`).
- Add PostgreSQL databases through `postgres.AddDatabase("<connection-string-name>")`; the name is part of the receiving service's connection-string contract.
- Declare dependencies with `.WithReference(...)` so Aspire supplies connection details and startup ordering.
- Use `.WithEnvironment(...)` for explicit endpoint/configuration contracts such as `Identity__Url`, `IdentityUrl`, and `CallBackUrl`.
- Derive endpoint values with `.GetEndpoint(...)`; do not hard-code localhost ports in service configuration.
- Keep stable service-discovery names aligned with the names used by dependent HTTP/gRPC clients.
- Preserve Identity callback wiring for applications that participate in authentication flows.

Do not make databases, Redis, or RabbitMQ externally reachable merely to simplify development.

## Endpoint and browser-test behavior

AppHost chooses the `http` launch profile when `ESHOP_USE_HTTP_ENDPOINTS=1`; otherwise it uses `https`. This exists for Playwright startup and CI compatibility.

- Do not remove or repurpose `ShouldUseHttpForEndpoints()` without validating browser tests.
- The local Playwright configuration starts AppHost unless `PLAYWRIGHT_BASE_URL` points at a deployed application.
- Do not start a second AppHost while Playwright is configured to manage it.

## Optional OpenAI configuration

The optional OpenAI section is disabled by default. When deliberately enabling it:

1. Prefer an existing connection string supplied through AppHost user secrets for local use.
2. Never commit API keys, endpoint credentials, subscription IDs, or local secret files.
3. Preserve the Catalog embedding and WebApp chat-model configuration contracts.
4. Use Azure infrastructure guidance for deployed Azure OpenAI resources; AppHost is not the production deployment mechanism.

## Validate the composition

1. Confirm .NET 8, Aspire workload, and Docker prerequisites using the local environment skill.
2. Build `src/eShop.AppHost/eShop.AppHost.csproj`.
3. Start AppHost and inspect the dashboard/resource health.
4. Verify each added dependency reaches a healthy state and receives its intended configuration.
5. Run focused service tests; run Playwright when endpoints, identity callbacks, or WebApp behavior changed.

## Guardrails

- Keep local resource names stable unless every affected connection and reference is migrated together.
- Do not use AppHost to define Azure deployment resources.
- Do not duplicate service configuration in AppHost and Azure Bicep without documenting the different local/deployed values.
- Treat Docker/Aspire startup failures as environment issues first; do not alter product code before checking prerequisites.
