---
name: dependency-update-triage
description: 'Review and safely apply eShop dependency updates. Use when handling Dependabot pull requests, NuGet/npm/GitHub Actions upgrades, dependency-review failures, vulnerability alerts, package license changes, or supply-chain-risk remediation.'
argument-hint: 'Dependency name, ecosystem, alert, or pull request'
user-invocable: true
---

# Triage eShop dependency updates

Use this workflow for every dependency update or dependency-security finding. It complements repository scanning tools with the repository's central package, testing, and GitHub Actions policies.

## 1. Classify the update

Identify the ecosystem and update type before editing:

| Ecosystem | Source of truth | Initial review |
| --- | --- | --- |
| NuGet | `Directory.Packages.props` | Compatibility, advisories, central-version impact |
| npm | `package.json` and lockfile | Playwright/tooling compatibility and advisories |
| GitHub Actions | workflow `uses:` references | Release provenance, full SHA pin, workflow permissions |

Check `.github/dependabot.yml` and `.github/dependency-review-config.yml` for the repository's automation and allow/deny rules.

`open-pull-requests-limit` (10 per ecosystem) caps only version-update pull requests; Dependabot does not support a numeric cap on open security-update pull requests. Security updates are intentionally left **ungrouped**: each vulnerability fix opens as its own PR and stands or fails on its own CI run, so an unrelated failing dependency never blocks a critical/high-severity fix. Do not add a blanket `applies-to: security-updates` group back; it would let one failing bundled fix block every other severity merged with it.

NuGet's `patch` version-update group is split into package families (`aspire`, `aspnetcore`, `efcore`, `observability`, `identity-server`, `testing`, `other-patch`) mirroring the version properties already documented in `Directory.Packages.props`, so a failing family only blocks its own PR. `cooldown` (5 days, 14 for majors) delays version updates only; it does not affect security updates.

**Severity triage has no PAT/App token in this repository**, so PR-level severity labels are not available (`dependabot/fetch-metadata`'s `alert-lookup` requires a PAT or GitHub App installation token; the default `GITHUB_TOKEN` cannot be granted a Dependabot-alerts read scope). Use the repository's Security tab, filtered to `is:open severity:critical,high`, as the source of truth for triage priority before working through open Dependabot PRs.

## 2. Assess security and compatibility

1. Read the advisory or Dependabot metadata and record the affected package, severity, exploitability, and fixed version.
2. Prefer the smallest patched version that resolves the issue unless compatibility requires a broader upgrade.
3. Read upstream release notes and migration guidance for major/minor updates.
4. Treat Aspire and `Microsoft.Extensions.ServiceDiscovery*` major updates as deliberate platform changes, not routine Dependabot work.
5. Check transitive impact and the number of projects sharing a centrally managed NuGet version.
6. For a new dependency, document its purpose, maintenance posture, license, source provenance, and why existing dependencies cannot meet the need.

Never suppress a vulnerability finding solely to make CI pass.

## 3. Make a minimal update

- Update NuGet versions only in `Directory.Packages.props`; project files reference centrally managed packages without versions.
- Preserve lockfiles and package manifests according to the existing tooling.
- For every remote GitHub Action, use a full 40-character commit SHA and an inline comment for its human-readable release.
- Do not combine unrelated version upgrades with security remediation.
- Do not add credentials, package-feed secrets, or untrusted install scripts to workflows.

## 4. Validate the change

1. Run dependency review and code scanning through CI where available.
2. Build and test the nearest affected service or test project.
3. Expand to affected functional tests when shared libraries, service discovery, database providers, messaging, or authentication packages changed.
4. Run browser tests when npm/Playwright/WebApp dependencies or authentication behavior changed.
5. For workflow dependency changes, validate YAML, permissions, pin length, and the changed workflow path.
6. Confirm the dependency review outcome includes both vulnerability and license policy checks.

Use `run-eshop-tests` to select the narrowest correct test scope. Report blocked Docker, workload, browser, or credential prerequisites separately from a failing assertion.

## 5. Document the pull request decision

Include:

- Advisory/alert reference and risk level.
- Old and new version or pinned commit.
- Compatibility/release-note review result.
- Exact validation performed and results.
- Any intentional deferral, compensating control, owner, and review date.

## Guardrails

- Do not merge grouped patch updates blindly; each package still needs provenance and compatibility review.
- Do not use floating action tags such as `@v4` or `@main`.
- Do not upgrade the .NET SDK, Aspire workload model, or package family as collateral work.
- Do not commit generated reports, local credentials, or dependency cache contents.
