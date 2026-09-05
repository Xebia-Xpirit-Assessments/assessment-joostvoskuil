---
name: github-actions-workflows
description: 'Create, review, and maintain GitHub Actions workflows for this repository. Use when adding CI, CD, deployment templates, reusable composite actions, or orchestration workflows, and when checking action version pinning, pull request triggers, environments, or workflow composition.'
argument-hint: 'Optional: workflow goal, target environment, or workflow files to create or review'
user-invocable: true
---

# Handle GitHub Actions workflows

Use this skill for all GitHub Actions changes in this repository. Keep workflows small, composable, auditable, and explicit about what they build and deploy.

## Repository workflow architecture

Organize automation into four layers:

1. **Composite actions** — reusable step sequences shared by multiple jobs or workflows.
2. **CI workflow** — validates code and runs checks for pull requests targeting `main`.
3. **CD workflow/template** — deploys a built artifact to an explicit GitHub Environment.
4. **Orchestration workflow** — coordinates CI and CD by calling the reusable workflows, potentially multiple times for multiple services or deployment stages.

Do not duplicate repeated setup, build, test, packaging, login, or deployment steps across workflow files. Extract those steps into a composite action under `.github/actions/<action-name>/action.yml`. Use inputs and outputs for configuration and data exchange; do not hard-code service-specific values when the same action can serve multiple callers.

## Action pinning policy

Every action referenced by `uses:` must be pinned to a full commit SHA. Never reference an action by:

- A major, minor, or patch version such as `@v4`, `@v4.2.0`, or `@main`.
- A branch, tag, or other floating ref.
- A short or abbreviated SHA.

Use the latest commit SHA for the intended action release. When adding or updating an action:

1. Identify the latest stable release and its complete commit SHA from the action's authoritative source.
2. Confirm that the SHA corresponds to the intended release or commit.
3. Pin `uses:` to the 40-character SHA.
4. Add an inline comment containing the human-readable release, for example `# v4`, so maintainers can audit the pin without replacing it with a floating reference.
5. Review and update pins deliberately; do not silently move to a newer action during unrelated workflow edits.

This applies to actions used directly by workflows and to actions used inside composite actions. Local actions should use a relative path such as `./.github/actions/build`, not a remote `uses:` reference.

## CI workflow

Keep CI in its own workflow, normally `.github/workflows/ci.yml`.

- Trigger CI on `pull_request` targeting `main`.
- Keep validation independent from deployment and GitHub Environment access.
- Use least-privilege `permissions`; begin with `contents: read` and add only permissions that a job requires.
- Run repeatable build, test, lint, packaging, and artifact-validation steps through composite actions where they are shared.
- Make failures actionable: preserve test results and build logs as artifacts when useful.
- Avoid deployment, mutable environment changes, or production credentials in CI.

A CI workflow may also expose `workflow_call` when the orchestration workflow needs to invoke the same CI logic. Preserve the pull-request trigger for normal developer validation.

## CD workflow and deployment template

Keep CD separate from CI. Implement deployment logic as a reusable workflow/template, normally `.github/workflows/cd.yml` or a clearly named deployment template.

- Accept deployment inputs through `workflow_call`, including the target service, artifact, and environment-specific settings.
- Require an explicit environment input. This repository supports `staging` and `production`; do not add a third environment without a documented requirement.
- Set the job's `environment` from the explicit input so GitHub Environment protection rules, secrets, and approvals apply consistently.
- Do not copy CI build logic into CD; deploy a validated artifact produced by CI or by a dedicated packaging composite action.
- Use environment-scoped secrets and variables rather than repository-wide secrets when the value belongs to an environment.
- Keep permissions minimal and declare them at workflow or job scope.

Staging is the automated pre-production target and runs the deployed browser-test gate. Production promotion must use the same immutable image tag and be protected by a manual GitHub Environment approval. Keep the template generic through inputs; do not duplicate it per environment.

## Azure authentication

Use OpenID Connect (OIDC) exclusively when GitHub Actions connects to Azure. Do not use stored Azure client secrets, passwords, publish profiles, or other long-lived credentials.

- Grant the workflow's job `id-token: write` permission in addition to the minimum permissions required for the job.
- Authenticate with the Azure login action using OIDC and the environment's identifiers.
- Provide `AZURE_SUBSCRIPTION_ID`, `AZURE_TENANT_ID`, and `AZURE_CLIENT_ID` separately for each GitHub Environment. Use environment-scoped variables or another explicitly documented per-environment configuration source; do not hard-code these values in workflow files.
- Keep the Azure federated identity credential and role assignments configured for the GitHub repository, branch or environment, and application identity being used.
- Treat `ApplicationId` as the Entra application/client ID. OIDC does not require an application secret.
- Do not fall back to secret-based Azure login if OIDC configuration is missing; fail clearly and fix the federated identity configuration instead.

## Orchestration workflow

Use a separate orchestration workflow when multiple CI or CD executions must be coordinated.

- Invoke reusable CI and CD workflows with `uses: ./.github/workflows/ci.yml` and `uses: ./.github/workflows/cd.yml` (or the repository's chosen filenames).
- Pass inputs and secrets explicitly with `with:` and `secrets:`.
- Call CI and CD as many times as required for the services or deployment units being orchestrated; do not duplicate their implementation.
- Express dependencies with `needs` so a CD invocation cannot run before its corresponding CI validation or artifact is ready.
- Give each invocation a distinct, descriptive job ID.
- Keep orchestration focused on ordering, fan-out/fan-in, inputs, and conditional execution. Put actual build, test, and deploy steps in the reusable workflows or composite actions.
- Do not use a normal step-level `uses:` call to emulate a reusable workflow; reusable workflows are called at the job level.

If orchestration is initiated manually, use `workflow_dispatch` with validated inputs. If it is initiated by another workflow, use `workflow_call`. Add other triggers only when there is a documented need.

## Composite action design

A composite action should:

- Have a focused responsibility and a descriptive name.
- Define typed-looking, documented inputs with sensible defaults where appropriate.
- Use `$GITHUB_OUTPUT` for outputs; do not rely on parsing log text between steps.
- Set `shell: bash` explicitly for shell steps unless another shell is required.
- Avoid hidden repository state and implicit working directories; expose paths as inputs when needed.
- Keep credentials out of command arguments and logs.
- Pin every external action used inside the composite action to a full SHA.
- Be usable by both CI and CD when the operation is genuinely shared.

## Review checklist

Before completing a workflow change, verify:

- [ ] Repeated steps are extracted into a composite action or reusable workflow rather than copied.
- [ ] Every remote `uses:` reference is pinned to a full 40-character commit SHA.
- [ ] Each SHA is annotated with its intended release or commit for auditability.
- [ ] CI is separate and triggers on pull requests targeting `main`.
- [ ] CD is separate from CI and uses the deployment template through `workflow_call`.
- [ ] CD targets an explicit `staging` or `production` GitHub Environment.
- [ ] Staging runs the deployed E2E gate and Production is protected by manual approval.
- [ ] Azure authentication uses OIDC exclusively, with `id-token: write` enabled for the Azure job.
- [ ] `SubscriptionId`, `TenantId`, and `ApplicationId` are supplied per GitHub Environment and are not hard-coded.
- [ ] Orchestration calls CI and CD as reusable workflows and can call them multiple times.
- [ ] Orchestration job dependencies use `needs` correctly.
- [ ] Inputs, outputs, secrets, and permissions are explicit and minimal.
- [ ] YAML syntax and workflow structure validate before merging.
- [ ] No credentials, tokens, or environment secrets are committed to the repository.
