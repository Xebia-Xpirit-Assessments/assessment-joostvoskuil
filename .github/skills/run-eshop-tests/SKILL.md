---
name: run-eshop-tests
description: 'Select, run, and troubleshoot tests for this .NET 8 Aspire eShop. Use when validating changes, running MSTest or xUnit projects, testing Aspire services with Docker, or running Playwright browser and end-to-end tests.'
argument-hint: 'Optional: changed area, test project, test name, or unit/functional/e2e scope'
user-invocable: true
---

# Run eShop tests

## Purpose

Run the smallest useful validation first, then expand only when the change or result requires it. This repository mixes MSTest unit tests, xUnit functional tests with Aspire-managed infrastructure, and Playwright end-to-end tests.

Use the separate [local environment skill](../prepare-local-eshop-environment/SKILL.md) when the .NET 8 SDK, Aspire workload, Docker engine, package restore, or AppHost itself is not ready. Do not duplicate that setup procedure here.

## Select the test scope

| Scope | Projects or files | Framework | Infrastructure |
|---|---|---|---|
| Basket unit | `tests/Basket.UnitTests` | MSTest, NSubstitute | None |
| Ordering unit | `tests/Ordering.UnitTests` | MSTest, NSubstitute | None |
| Client unit | `tests/ClientApp.UnitTests` | MSTest, NSubstitute | May require MAUI workloads; excluded from `eShop.Web.slnf` |
| Catalog functional | `tests/Catalog.FunctionalTests` | xUnit, Aspire fixtures | Docker; fixture starts PostgreSQL |
| Ordering functional | `tests/Ordering.FunctionalTests` | xUnit, Aspire fixtures | Docker and Aspire-managed dependencies |
| Browser end-to-end | `e2e/*.spec.ts` | Playwright | AppHost and its Docker dependencies |

Choose scope in this order:

1. Run the test project nearest the changed production project.
2. Filter to a test name only while iterating on a focused failure.
3. Run all affected unit and functional projects after the focused test passes.
4. Use `eShop.Web.slnf` for broad backend/web validation. It intentionally excludes `ClientApp.UnitTests` and other MAUI projects.
5. Run Playwright only for user-visible flows, authentication, routing, or cross-service behavior exercised through `WebApp`.

## Unit tests

Run a targeted unit project from the repository root, for example:

```sh
dotnet test tests/Basket.UnitTests/Basket.UnitTests.csproj
```

or:

```sh
dotnet test tests/Ordering.UnitTests/Ordering.UnitTests.csproj
```

Follow the existing project style when adding tests:

- Use `[TestClass]` and `[TestMethod]`.
- Use NSubstitute for test doubles.
- Name tests after the behavior and expected outcome.
- Keep unit tests independent of Docker, network services, and the Aspire AppHost.

Treat `tests/ClientApp.UnitTests` separately. Check the MAUI prerequisites before running it; do not install MAUI workloads for an unrelated backend change.

## Functional tests

Functional fixtures start Aspire resources and require a working Docker engine. Before running a functional project:

```sh
docker info
```

Then run the affected project:

```sh
dotnet test tests/Catalog.FunctionalTests/Catalog.FunctionalTests.csproj
```

```sh
dotnet test tests/Ordering.FunctionalTests/Ordering.FunctionalTests.csproj
```

Follow the existing functional-test style:

- Use xUnit `[Fact]` tests and the service's `IClassFixture<TFixture>`.
- Let the fixture own startup and disposal of Aspire resources.
- Exercise the HTTP contract through `HttpClient`; do not bypass the API to make a functional test easier.
- Use the existing API-version handler when the service expects a version.
- Make test data and assertions deterministic.

If a fixture cannot start PostgreSQL or another container, classify it as an environment failure before changing production code. Use the [local environment skill](../prepare-local-eshop-environment/SKILL.md) for Docker, Aspire, SDK, or restore repair.

## Broad backend validation

The web solution filter contains the backend/web projects and their unit and functional tests while avoiding optional MAUI projects:

```sh
dotnet test eShop.Web.slnf
```

Docker must be available because this command includes the functional projects. Prefer targeted projects during development so unrelated infrastructure does not obscure the first useful failure.

## Playwright end-to-end tests

[`playwright.config.ts`](../../../playwright.config.ts) starts `src/eShop.AppHost/eShop.AppHost.csproj` through its `webServer` configuration and targets `http://localhost:5045`. Do not start a duplicate AppHost unless reusing an already running server intentionally.

Install JavaScript dependencies and the configured Chromium browser when needed:

```sh
npm ci
```

```sh
npx playwright install chromium
```

The authenticated setup in [`e2e/login.setup.ts`](../../../e2e/login.setup.ts) reads these values from the ignored root `.env` file:

```dotenv
USERNAME1=replace-with-local-test-username
PASSWORD=replace-with-local-test-password
```

Never echo, log, commit, or place real credentials in source files. If credentials are unavailable, run only the unauthenticated project when it covers the change:

```sh
npx playwright test --project="e2e tests without logged in"
```

Run the complete end-to-end suite only when authenticated scenarios are configured:

```sh
npx playwright test
```

## Deployed Staging end-to-end gate

The reusable Staging E2E workflow runs the same suite against the deployed WebApp rather than starting AppHost. It supplies `PLAYWRIGHT_BASE_URL` from the public Container App FQDN and authenticated test credentials through the protected `staging` GitHub Environment.

- Do not configure a local AppHost when `PLAYWRIGHT_BASE_URL` is set; `playwright.config.ts` intentionally omits its `webServer` in this case.
- Treat `E2E_USERNAME` and `E2E_PASSWORD` as GitHub Environment secrets. Never copy their values to a workflow, `.env`, test output, logs, or source control.
- The workflow publishes JUnit output from `test-results/e2e-junit.xml` and uploads Playwright reports/traces for diagnostics. Inspect generated artifacts, but do not commit them.
- When a deployed E2E test fails, first identify whether it is an assertion, application deployment/health issue, Azure access/configuration issue, or test-account/credential issue before changing code.

Playwright generates `playwright/.auth`, `playwright-report`, and `test-results`. Inspect these outputs when diagnosing failures, but do not edit or commit them.

## Failure triage

1. Capture the failing test name and the first actionable error.
2. Classify the failure:
   - **Compilation or restore**: fix the source error or use the environment skill.
   - **Infrastructure**: verify Docker, Aspire, ports, and container startup before editing application behavior.
   - **Browser setup**: verify npm dependencies and Chromium installation.
   - **Authentication setup**: verify local environment variables without printing their values.
   - **Assertion**: reproduce with the smallest test/filter and investigate the changed behavior.
3. Fix the root cause, rerun the smallest failing scope, then expand to the affected suite.
4. Report commands and outcomes accurately. Do not claim a suite passed when it was skipped or blocked.

## Completion checklist

- [ ] The smallest relevant test was run first.
- [ ] New tests use the existing framework and fixture style for their project.
- [ ] Functional-test Docker requirements were checked.
- [ ] Playwright credentials and generated auth state remain local and uncommitted.
- [ ] Deployed Staging tests use `PLAYWRIGHT_BASE_URL` and GitHub Environment secrets, never local credentials or AppHost.
- [ ] Environment failures were not misreported as product regressions.
- [ ] Broader affected tests were run after the focused test passed.
- [ ] `bin`, `obj`, Playwright reports, auth state, and test output were not edited or committed.
