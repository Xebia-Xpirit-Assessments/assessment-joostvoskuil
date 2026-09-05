# eShop repository guidelines

## Repository and architecture

- This is a .NET 8 services-based eShop orchestrated locally by .NET Aspire. Respect service boundaries; do not move domain behavior or persistence concerns between projects merely to reuse code.
- Use the SDK selected by [`global.json`](../global.json). Do not upgrade the SDK, Aspire workload model, target frameworks, or package families as part of an unrelated change.
- Treat [`src/eShop.AppHost/Program.cs`](../src/eShop.AppHost/Program.cs) as the local composition root for services and infrastructure such as PostgreSQL, RabbitMQ, and Redis.
- Put cross-cutting hosting behavior in `src/eShop.ServiceDefaults` only when it should apply across services. Keep service-specific registration in that service's `Extensions/Extensions.cs` via `AddApplicationServices`.
- Follow the nearest project's established pattern. The APIs, workers, Blazor applications, MAUI applications, domain projects, and infrastructure projects intentionally have different responsibilities.

## C# conventions

- [`Directory.Build.props`](../Directory.Build.props) enables preview C# and implicit usings. Modern syntax already used nearby—file-scoped namespaces, primary constructors, records, collection expressions, and target-typed construction—is acceptable.
- Preserve local namespace, nullability, constructor, and file-organization style. Nullable annotations are not enabled uniformly, so do not introduce a repository-wide nullable policy in a focused change.
- Use async APIs for I/O and propagate `CancellationToken` when the surrounding contract supports one. Do not add cancellation parameters to domain behavior that performs no I/O.
- Use dependency injection rather than service location or manually constructed infrastructure dependencies. Register explicit lifetimes and bind options through configuration.
- Use structured `ILogger` templates with named properties. Never log credentials, tokens, complete payment-card data, or other secrets; follow the masking and logging boundary in [`Ordering.API/Apis/OrdersApi.cs`](../src/Ordering.API/Apis/OrdersApi.cs).
- Prefer focused changes that preserve existing public contracts. Do not reformat or modernize unrelated code.

## Services and HTTP APIs

- Compose API startup from `builder.AddServiceDefaults()`, service-specific `builder.AddApplicationServices()`, Problem Details, API versioning/OpenAPI where applicable, and `app.MapDefaultEndpoints()`. See [`Catalog.API/Program.cs`](../src/Catalog.API/Program.cs) and [`eShop.ServiceDefaults/Extensions.cs`](../src/eShop.ServiceDefaults/Extensions.cs).
- Extend backend HTTP APIs with versioned Minimal API route groups and endpoint-mapping extension methods. Prefer typed `Results<...>` and `TypedResults` over untyped responses.
- Group handler dependencies into the existing `[AsParameters]` service records/classes when an endpoint needs several collaborators.
- Preserve authentication and authorization boundaries. Use the shared authentication and claims helpers in `eShop.ServiceDefaults` rather than parsing tokens or duplicating claim rules.
- For ordering commands that use `x-requestid`, retain the `IdentifiedCommand<TCommand, TResult>` idempotency flow and reject empty request IDs.

## Domain, persistence, and messaging

- Keep business invariants inside aggregates. Use behavior methods, private setters, and private collections exposed as read-only views; do not let endpoint or persistence code mutate aggregate state directly. [`Ordering.Domain/AggregatesModel/OrderAggregate/Order.cs`](../src/Ordering.Domain/AggregatesModel/OrderAggregate/Order.cs) is the primary example.
- Raise domain events for in-process side effects and preserve dispatch through `OrderingContext.SaveEntitiesAsync`. Keep repositories and `IUnitOfWork` as the write boundary.
- Keep EF Core mappings in entity configuration classes and apply them from the owning `DbContext`. Do not hand-edit generated migration files unless the task specifically requires migration repair.
- Integration events must implement the existing event contracts, use `IIntegrationEventHandler<TEvent>`, and be registered through the event-bus builder. Preserve the integration-event log/outbox transaction flow; do not publish directly in a way that can separate an event from its state change.

## Dependencies and generated content

- NuGet versions are centrally managed. Add package references without versions to project files and change versions only in [`Directory.Packages.props`](../Directory.Packages.props).
- For routine backend/web work, restore, build, and test [`eShop.Web.slnf`](../eShop.Web.slnf), not the full solution; the full solution includes optional MAUI workload requirements.
- Do not edit `bin/`, `obj/`, `artifacts/`, Playwright auth/report/test-output directories, or other generated build content.
- Do not commit `.env`, credentials, tokens, connection strings containing secrets, or generated Playwright storage state.

## Tests and validation

- Add or update the smallest test suite that demonstrates the behavior changed.
- Preserve the framework already used by the project: MSTest with NSubstitute for unit-test projects, xUnit with Aspire fixtures for backend functional tests, and Playwright for browser end-to-end tests.
- Functional tests require Docker because their fixtures start Aspire-managed containers. End-to-end tests use the `webServer` configured in [`playwright.config.ts`](../playwright.config.ts).
- Use the [`run-eshop-tests`](skills/run-eshop-tests/SKILL.md) skill for selecting and running test suites. Use the existing [`prepare-local-eshop-environment`](skills/prepare-local-eshop-environment/SKILL.md) skill for SDK, Aspire workload, Docker, restore, or AppHost setup failures.
- Report exactly what was run and distinguish assertion failures from missing workloads, unavailable Docker, unavailable browsers, or absent local credentials.

### Copilot Cloud agent test requirements

- Keep `DOTNET_SYSTEM_NET_DISABLEIPV6=0` in the environment of AppHost and functional-test processes. Configure it persistently under repository **Settings > Secrets and variables > Agents > Variables**; if the session still supplies `1`, override it to `0` for those commands. A Cloud session with this variable set to `1` caused .NET clients to fail against Aspire DCP's IPv6-only loopback listener with `No data available ([::1]:<port>)`, even though native IPv6 TCP probes succeeded. Enabling IPv6 in .NET resolved AppHost startup and both backend functional suites; do not misdiagnose this as a firewall failure or assume an Aspire version incompatibility.
- When applicable, the Copilot Cloud agent must start the application through the Aspire AppHost and directly test its modifications (for example, by exercising the affected API endpoint or browser workflow). For browser-visible changes, capture screenshots demonstrating the tested behavior and attach them to the active pull request or Cloud session; do not commit generated screenshot artifacts. Include the attached evidence in the final summary. If startup, direct testing, or attaching evidence is blocked, report the exact command or action and environment limitation.
- Before completing a task, the Copilot Cloud agent must run the unit tests for every impacted component, API, or project area. Select the narrowest relevant test project rather than relying only on a full-solution build; run both `Basket.UnitTests` and `Ordering.UnitTests` when the change crosses their boundaries.
- The Copilot Cloud agent must also run all backend functional test projects: `tests/Catalog.FunctionalTests/Catalog.FunctionalTests.csproj` and `tests/Ordering.FunctionalTests/Ordering.FunctionalTests.csproj`.
- Run functional tests with the .NET 8 SDK and restored .NET Aspire workload. Docker must be available because the Aspire fixtures start PostgreSQL and other managed resources.
- Do not silently skip required tests. If the Cloud environment lacks Docker, the Aspire workload, MAUI tooling, browsers, or credentials, report the exact blocked command and environment limitation, and distinguish that limitation from a test failure.
- Include the executed test projects and their pass/fail/blocked status in the final task summary.
