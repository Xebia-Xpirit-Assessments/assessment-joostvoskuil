---
name: repository-controls-review
description: 'Assess this repository’s GitHub Enterprise security, governance, compliance, and delivery controls. Use when auditing repository readiness, reviewing supply-chain safeguards, preparing ISO 27001 evidence, or creating a board-facing blueprint assessment.'
argument-hint: 'Assessment scope, control area, or target standard'
user-invocable: true
---

# Review repository controls

Perform an evidence-based review of this repository as a blueprint for eShop teams. Report what repository files prove, what requires GitHub organization/environment configuration, and what is missing. Do not claim an organization-level control is enabled merely because repository files support it.

## Review method

1. Define the scope: full blueprint, security, CI/CD, governance, onboarding, compliance evidence, or AI enablement.
2. Inspect only relevant, version-controlled evidence first.
3. Separate findings into **implemented**, **partially evidenced**, **requires GitHub configuration**, **missing**, and **out of scope**.
4. Record each finding with evidence path, risk/benefit, owner, and concrete next action.
5. Prioritize material risks to supply-chain integrity, deployment identity, production changes, and sensitive-data handling.

## Control matrix

| Control area | Repository evidence to inspect | Verify outside the repository |
| --- | --- | --- |
| Change control | CI workflows, `CONTRIBUTING.md`, PR checks | Rulesets/branch protection, required reviewers, merge policy |
| Ownership | `CODEOWNERS`, team documentation | Team membership and review enforcement |
| Dependency security | `dependabot.yml`, dependency review, dependency submission, `Directory.Packages.props` | Dependabot alerts, alert-dismissal permissions |
| Code and secret scanning | CodeQL and secret-scanning configuration | Security feature enablement, alert triage SLA |
| Workflow supply chain | all workflow/composite action `uses:` entries | Actions policy, allowed publishers, runner isolation |
| Delivery security | deployment workflows, Bicep, Azure configuration | GitHub Environment approvals, OIDC federated credentials, Azure RBAC |
| Evidence retention | artifact/report configuration | Organization retention policy and audit-log retention |
| Secure reporting | `SECURITY.md` or equivalent | Private vulnerability reporting and incident ownership |
| AI enablement | `.github` customizations and contributor guidance | Copilot policy, content exclusions, data controls |

## Required review checks

### GitHub Actions and delivery

- Every remote action is a complete 40-character SHA with a readable release comment.
- Permissions are least privilege and `id-token: write` appears only where Azure OIDC requires it.
- CI does not deploy or consume production secrets.
- Deployment uses environment-scoped configuration and protected approval gates where required.
- Immutable image tags are promoted; `latest` is not used for production promotion.
- Infrastructure and application deployment order matches the documented Bicep/azd model.

### Supply-chain protections

- Dependency review blocks the configured severity and license-policy violations.
- Dependabot supports NuGet, npm, and GitHub Actions, with deliberate grouping/ignore rules.
- Central NuGet package management is retained.
- CodeQL covers the repository's relevant languages and uses a suitable build approach.
- Secret scanning and push protection are confirmed in repository/organization settings, not inferred from source files.

### Governance and onboarding

- Contribution guidance points to local setup, testing, security reporting, and review expectations.
- Ownership rules exist for sensitive paths such as workflows, infrastructure, dependency policy, and application areas.
- Branch/ruleset enforcement, environment reviewers, and bypass permissions are verified externally.
- The local development experience documents its Docker, .NET 8, Aspire, and optional MAUI requirements.

## Reporting format

Produce a concise table:

| Status | Control | Evidence | Gap or risk | Next action | Owner |
| --- | --- | --- | --- | --- | --- |

Finish with the three highest-priority actions and distinguish repository changes from GitHub/Azure administrator actions. Avoid exposing identifiers, credentials, alert payloads, or personal data in the report.
