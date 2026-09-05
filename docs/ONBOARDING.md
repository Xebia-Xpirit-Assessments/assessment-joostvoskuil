# eShop developer onboarding

This is the starting point for the eShop development teams. It describes the
repository's Way of Work and points to the detailed documents, workflows,
templates, and skills that implement it.

Use this document to answer three questions:

1. How do I prepare my environment and make a change safely?
2. Which tests, reviews, and status checks apply to my change?
3. Where do I find the guidance for dependencies, security, AI assistance, and
   delivery?

This index is intentionally concise. The linked files remain the source of
truth for commands, workflow behavior, and policy details.

## How to read this guide

The repository contains controls at different layers:

- **Implemented in the repository** means the behavior is defined in source,
  workflow, or configuration files.
- **Partially evidenced** means the repository defines an intended behavior,
  but its enforcement or configuration must be checked elsewhere.
- **Administrator configuration** means the control is owned by GitHub or
  Azure settings and cannot be established from repository files alone.

Do not treat a workflow definition as proof that a branch rule, required status
check, environment approval, or security setting is enabled. Those settings
must be verified in GitHub or Azure.

## Start here

1. Read the [eShop setup guide](../README-eShop.md).
2. Install the SDK selected by [`global.json`](../global.json), Docker, and the
   .NET Aspire workload. The [local environment skill](../.github/skills/prepare-local-eshop-environment/SKILL.md)
   explains the supported setup paths and common failures.
3. Restore and build [`eShop.Web.slnf`](../eShop.Web.slnf), then start the
   local application through [`src/eShop.AppHost/Program.cs`](../src/eShop.AppHost/Program.cs).
4. Before editing, read the nearest project's established pattern and the
   applicable repository skill.
5. Run the narrowest relevant tests, open a pull request, and address every
   required check and review comment.

The [dev container](../.devcontainer/devcontainer.json) and GitHub Codespaces
provide a supported alternative. They prepare dependencies but do not start
the Aspire application automatically.

## Repository orientation

eShop is a .NET 8 services-based application orchestrated locally by .NET
Aspire. The AppHost composes the application services and infrastructure such
as PostgreSQL, RabbitMQ, and Redis. Service boundaries are intentional:

| Area | Main location | Typical validation |
| --- | --- | --- |
| Web application | [`src/WebApp`](../src/WebApp) and [`src/WebAppComponents`](../src/WebAppComponents) | Web App build and ClientApp unit tests |
| Identity | [`src/Identity.API`](../src/Identity.API) | Identity API build |
| Basket | [`src/Basket.API`](../src/Basket.API) | Basket API build and Basket unit tests |
| Catalog | [`src/Catalog.API`](../src/Catalog.API) | Catalog API build and Catalog functional tests |
| Ordering | [`src/Ordering.API`](../src/Ordering.API), [`src/Ordering.Domain`](../src/Ordering.Domain), and [`src/Ordering.Infrastructure`](../src/Ordering.Infrastructure) | Ordering build, unit tests, and functional tests |
| Shared behavior | [`src/eShop.ServiceDefaults`](../src/eShop.ServiceDefaults), [`src/Shared`](../src/Shared), and event bus projects | Multiple affected service validations |
| Infrastructure | [`infra`](../infra) | Bicep validation and deployment review |

Keep business behavior in its owning domain and persistence boundary. Use
dependency injection and the local service registration patterns instead of
moving code between projects for convenience. The repository's
[Copilot instructions](../.github/copilot-instructions.md) describe the
architecture and coding conventions in detail.

## The development workflow

### 1. Classify the change

Identify the owning service and whether the change affects shared libraries,
eventing, infrastructure, dependencies, or deployment. The pull-request
workflow uses path-based routing, so a shared change can intentionally select
multiple service validations.

Use the skill that matches the work:

| Change | Skill |
| --- | --- |
| Prepare SDK, Aspire, Docker, or local tooling | [`prepare-local-eshop-environment`](../.github/skills/prepare-local-eshop-environment/SKILL.md) |
| Select or troubleshoot tests | [`run-eshop-tests`](../.github/skills/run-eshop-tests/SKILL.md) |
| Change AppHost composition, resources, or service discovery | [`eshop-aspire-composition`](../.github/skills/eshop-aspire-composition/SKILL.md) |
| Add a deployable service | [`add-eshop-service`](../.github/skills/add-eshop-service/SKILL.md) |
| Change GitHub Actions or reusable workflows | [`github-actions-workflows`](../.github/skills/github-actions-workflows/SKILL.md) |
| Review a dependency or Dependabot update | [`dependency-update-triage`](../.github/skills/dependency-update-triage/SKILL.md) |
| Change Azure or Bicep infrastructure | [`infra-deployment-standards`](../.github/skills/infra-deployment-standards/SKILL.md) |
| Review repository security and governance controls | [`repository-controls-review`](../.github/skills/repository-controls-review/SKILL.md) |

### 2. Preserve the service boundary

Follow the nearest project's existing pattern. In particular:

- Keep API mapping in versioned Minimal API route groups and endpoint mapping
  extensions.
- Keep business invariants inside aggregates and domain behavior.
- Keep EF Core mappings in entity configuration classes owned by the relevant
  `DbContext`.
- Preserve domain-event, integration-event, and outbox flows.
- Use the shared authentication, claims, logging, and telemetry helpers.
- Do not edit generated `bin/`, `obj/`, artifact, Playwright output, or local
  credential files.

### 3. Validate locally and open a pull request

Run focused tests first, then open a pull request targeting `main`. Explain the
change, test evidence, dependency or security impact, and deployment impact.
Reviewers should be able to understand what changed and why without deriving
the intent from the diff alone.

## Workflows and reusable templates

The main pull-request workflow is
[`ci.yml`](../.github/workflows/ci.yml). It detects affected components and
calls the reusable
[`template-build-service.yml`](../.github/workflows/template-build-service.yml)
for the selected services. It also validates Bicep when infrastructure files
change and finishes with the `PR validation` job.

The reusable build template provides these checks:

- `Build (<service>)`
- `Validate Docker context (<service>)`
- `Unit tests (<service>)` where unit tests exist
- `Functional tests (<service>)` where functional tests exist
- Test reports and Cobertura coverage uploads

Deployment is split into reusable templates and service-specific callers:

- [`template-publish-service.yml`](../.github/workflows/template-publish-service.yml)
  builds and publishes one selected image, resolves its digest, and creates
  attestations.
- [`template-deploy-service.yml`](../.github/workflows/template-deploy-service.yml)
  deploys an immutable image reference and verifies provenance before updating
  the Container App.
- [`template-run-e2e-tests.yml`](../.github/workflows/template-run-e2e-tests.yml)
  runs staging browser tests.
- [`deploy-webapp.yml`](../.github/workflows/deploy-webapp.yml) and the other
  `deploy-*.yml` workflows supply service-specific callers.

Reusable workflow templates define shared behavior; local composite actions
provide shared setup steps; skills provide human and Copilot guidance for a
class of tasks. Keep those responsibilities separate when extending the
repository.

## Testing

Choose the smallest test scope that gives confidence in the change, then
expand it when shared infrastructure, messaging, persistence, authentication,
or deployment behavior is affected.

| Change area | Test project or workflow | Requirements |
| --- | --- | --- |
| Basket behavior | [`tests/Basket.UnitTests`](../tests/Basket.UnitTests) | .NET SDK; no Docker |
| Ordering domain/API behavior | [`tests/Ordering.UnitTests`](../tests/Ordering.UnitTests) | .NET SDK; no Docker |
| Catalog service behavior | [`tests/Catalog.FunctionalTests`](../tests/Catalog.FunctionalTests) | Docker, Aspire fixture, and PostgreSQL container |
| Ordering integration behavior | [`tests/Ordering.FunctionalTests`](../tests/Ordering.FunctionalTests) | Docker and Aspire-managed dependencies |
| Client application behavior | [`tests/ClientApp.UnitTests`](../tests/ClientApp.UnitTests) | Full required MAUI workloads; not included in `eShop.Web.slnf` |
| Browser behavior | [`e2e`](../e2e) through [`playwright.config.ts`](../playwright.config.ts) | AppHost, Docker-backed resources, and Chromium locally |
| Staging browser behavior | [`template-run-e2e-tests.yml`](../.github/workflows/template-run-e2e-tests.yml) | Deployed URL and staging credentials |

Functional tests require Docker. Local Playwright tests start the AppHost;
deployed tests use `PLAYWRIGHT_BASE_URL` and do not start it. Screenshots,
JUnit output, and HTML reports are generated according to the Playwright
configuration. The [testing skill](../.github/skills/run-eshop-tests/SKILL.md)
contains the full selection and failure-classification guidance.

The ClientApp unit-test project has a special MAUI workload requirement. Do
not misclassify a missing workload or unavailable browser/Docker dependency as
an assertion failure; report the environmental blocker separately.

## Code quality and status checks

Code quality is part of the pull-request status-check experience. The
repository defines the following checks:

- **PR validation** — confirms that every selected validation completed
  successfully or was intentionally skipped.
- **Build and Docker context checks** — confirm that affected services restore,
  compile, and have the expected Docker inputs.
- **Unit and functional test checks** — execute the tests selected by the
  affected service.
- **Validate Bicep templates** — checks the infrastructure templates when they
  are affected.
- **CodeQL analysis** — scans GitHub Actions, C#, and JavaScript/TypeScript on
  pushes and pull requests to `main`, plus a weekly scheduled scan.

When a check fails, first decide whether it is an assertion/code failure or an
environmental issue such as Docker, an SDK/workload, a browser, or credentials.
Use the relevant skill, inspect the uploaded test artifacts, fix the root
cause, and rerun the affected validation.

These workflow files show what can run. Whether these checks are required for
merging is an **administrator configuration** question controlled by GitHub
branch rulesets. Confirm the required-check names with the repository owners.

## Dependabot and dependency changes

Dependabot runs daily for:

- NuGet packages under `src` and `tests`
- npm dependencies at the repository root
- GitHub Actions dependencies

The configuration groups routine patch updates by ecosystem or package family,
uses cooldowns for version updates, and deliberately leaves security updates
ungrouped so one failing update cannot block unrelated vulnerability fixes.
Aspire and Service Discovery major updates are ignored by routine automation
because they require a deliberate platform change.

NuGet versions are centrally managed in
[`Directory.Packages.props`](../Directory.Packages.props). Review the
exception for MAUI tests before changing package versions.

### Dependabot way of working

For every update:

1. Classify the ecosystem, package, update type, and security severity.
2. Read the advisory, release notes, and migration guidance.
3. Prefer the smallest compatible security fix; do not bundle unrelated work.
4. Check transitive impact and centrally managed consumers.
5. Run the narrowest affected tests, then expand for shared frameworks,
   messaging, persistence, authentication, or browser changes.
6. Confirm dependency review passes vulnerability and license checks.
7. Record the version change, risk, compatibility review, validation, and any
   intentional deferral in the pull request.

Use the [dependency-update-triage skill](../.github/skills/dependency-update-triage/SKILL.md)
for the complete workflow. The related automation is defined in
[`dependabot.yml`](../.github/dependabot.yml),
[`dependency-review.yml`](../.github/workflows/dependency-review.yml),
[`dependency-submission.yml`](../.github/workflows/dependency-submission.yml),
and [`dependency-review-config.yml`](../.github/dependency-review-config.yml).

## Security scanning and safe development

The repository includes these source-controlled security checks:

- CodeQL scanning for Actions, C#, and JavaScript/TypeScript.
- Dependency review on pull requests, failing at moderate or higher severity
  and checking configured license policy.
- Dependency snapshots for NuGet and npm dependencies.
- Artifact provenance and SBOM attestations during image publishing.

Do not put credentials, tokens, connection strings containing secrets, payment
data, production data, or private customer information into source files,
issues, logs, or Copilot prompts. Follow the repository logging and masking
rules in the [Copilot instructions](../.github/copilot-instructions.md).

Secret scanning, push protection, Dependabot alerts, and private vulnerability
reporting are GitHub or organization controls. They are not proved by the
workflow files in this repository. Administrators must verify those settings
and provide the organization's approved security-reporting route. There is
currently no repository-local `SECURITY.md` in this scope.

## Attestation and release

The intended delivery path is:

1. A reviewed change reaches protected `main` after the required checks pass.
2. The publisher builds one image tagged with the source commit and resolves
   its immutable `sha256` digest.
3. The publisher creates SLSA build provenance and an SPDX SBOM attestation.
4. Provenance is verified against this repository, source commit, signer
   workflow, and GitHub's OIDC issuer.
5. The signed-build evidence artifact retains the SBOM and deployment record.
6. Staging end-to-end tests pass.
7. An authorized production environment approval permits deployment of the
   same immutable image digest; production must not rebuild from source.

Read [Signed build and promotion policy](../.github/SUPPLY-CHAIN-SECURITY.md)
for verification commands, evidence expectations, and administrator controls.
The deployment documentation and workflows should be reconciled whenever
registry or environment topology changes; do not assume that a workflow file
alone proves production approval, branch protection, or Azure RBAC.

## Copilot and AI enablement

Copilot is an accelerator, not an approval mechanism. Before using Copilot in
this repository:

1. Read [`.github/copilot-instructions.md`](../.github/copilot-instructions.md).
2. Select the applicable repository skill before asking for implementation or
   troubleshooting help.
3. Give Copilot the smallest useful context and ask it to preserve service
   boundaries and existing patterns.
4. Review generated code, run the relevant tests, and satisfy all required
   security and quality checks yourself.

The repository skills are task-specific playbooks rather than generic prompt
collections. They cover local setup, test selection, Aspire composition,
adding services, GitHub Actions, dependency triage, infrastructure standards,
and governance review. Copilot setup steps are defined in
[`copilot-setup-steps.yml`](../.github/workflows/copilot-setup-steps.yml), and
automated review guidance is in
[`copilot-code-review.yml`](../.github/workflows/copilot-code-review.yml).

Allowed uses include repository navigation, explanation, test scaffolding,
refactoring proposals, and review assistance. Human developers remain
responsible for correctness, security, privacy, licensing, and the final
change. Optional Azure OpenAI/Semantic Kernel functionality documented in
[`README-eShop.md`](../README-eShop.md) is an application feature, not a
prerequisite for ordinary development.

## Governance, ownership, and escalation

Contributors should follow [`CONTRIBUTING.md`](../CONTRIBUTING.md) and the
[Code of Conduct](../CODE-OF-CONDUCT.md). Review ownership is currently
declared in [`.github/CODEOWNERS`](../.github/CODEOWNERS), but ownership should
be confirmed with the team leads for service, infrastructure, workflow, and
security changes.

The following controls require administrator verification outside the code
files:

- Protected `main` ruleset, pull-request review, and required status checks.
- CODEOWNER enforcement and team ownership coverage.
- Dependabot alerts, secret scanning, and push protection.
- Staging and production environment reviewers and deployment restrictions.
- Azure OIDC federated credentials, RBAC, and ACR retention.
- GitHub audit-log and Actions-artifact retention.

For a control review, use the
[repository controls skill](../.github/skills/repository-controls-review/SKILL.md).
For Azure deployment behavior, use [`infra/README.md`](../infra/README.md) and
the [infrastructure standards skill](../.github/skills/infra-deployment-standards/SKILL.md).

## Troubleshooting route

| Symptom | Start with |
| --- | --- |
| SDK, Aspire, Docker, or restore failure | [Local environment skill](../.github/skills/prepare-local-eshop-environment/SKILL.md) |
| Test selection or test failure classification | [Testing skill](../.github/skills/run-eshop-tests/SKILL.md) |
| AppHost, Redis, RabbitMQ, PostgreSQL, or service discovery issue | [Aspire composition skill](../.github/skills/eshop-aspire-composition/SKILL.md) |
| Dependabot, advisory, license, or package issue | [Dependency triage skill](../.github/skills/dependency-update-triage/SKILL.md) |
| Workflow, action, permission, or status-check issue | [GitHub Actions skill](../.github/skills/github-actions-workflows/SKILL.md) |
| Azure, Bicep, deployment, or identity issue | [Infrastructure standards skill](../.github/skills/infra-deployment-standards/SKILL.md) |
| Governance, ownership, or security-control question | [Repository controls skill](../.github/skills/repository-controls-review/SKILL.md) |

When escalating, include the affected service, commit or pull request, exact
failed check, relevant logs or artifact link, tests attempted, and whether the
failure is an assertion or an environmental prerequisite.

## Related entry points

- [Contribution guidance](../CONTRIBUTING.md)
- [Application setup and deployment](../README-eShop.md)
- [Testing overview](../tests/README.md)
- [Signed build and promotion policy](../.github/SUPPLY-CHAIN-SECURITY.md)
- [Repository Copilot instructions](../.github/copilot-instructions.md)