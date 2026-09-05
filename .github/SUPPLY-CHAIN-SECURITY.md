# Signed build and promotion policy

## Objective

This repository uses GitHub artifact attestations to establish the provenance and software bill of materials (SBOM) for every container image promoted to production. This is a delivery control supporting ISO 27001-aligned change control, configuration management, supplier security, and operational evidence retention; it is not a claim of ISO 27001 certification.

## Required delivery path

1. A protected `main` branch receives a reviewed change that has passed required build, test, dependency, and code-security checks.
2. The protected `shared` publisher workflow builds and pushes one image tagged with the source commit SHA to the shared ACR, resolves its immutable `sha256` manifest digest, and generates GitHub-signed SLSA provenance and an SPDX SBOM attestation for that digest.
3. The publisher verifies provenance against this repository, `template-publish-service.yml`, the GitHub Actions OIDC issuer, and the source commit before either deployment environment consumes the image. It retains the SBOM and a deployment-evidence record for 365 days.
4. Staging end-to-end tests pass. A protected `production` GitHub Environment requires an authorized approval.
5. Production deploys the same shared-ACR digest as Staging. It must not rebuild from source, overwrite an existing commit-SHA tag, or deploy a digest that differs from the verified publisher output.

GitHub Releases are optional. Create a protected semantic version tag and a GitHub Release when a human-facing release catalogue, release notes, or external binary distribution is required. A Release is not the signing mechanism and is not required for container provenance, SBOMs, or digest promotion.

## Why two attestations per image

The publisher signs two separate attestations for every image digest. They answer different questions and must both be checked:

| Attestation | Question it answers | Predicate type |
| --- | --- | --- |
| Build provenance | Was this exact digest built by our trusted `template-publish-service.yml` workflow, from this exact commit? | `https://slsa.dev/provenance/v1` |
| SBOM | What components/dependencies does this image contain? | SPDX |

`gh attestation verify` without `--predicate-type` only checks the provenance attestation by default. The SBOM attestation is retrieved separately (see the `signed-build-evidence-*` artifact) and is not itself required to pass for deployment; it exists so components can be identified later without re-scanning the image.

## Verification and evidence

Authorized operators can verify provenance for an authenticated ACR image with GitHub CLI. Require the repository, reusable signer workflow, and source commit when verifying; do not accept an attestation merely because it exists.

```text
gh attestation verify oci://<registry>/<repository>@sha256:<digest> \
  --repo Xebia-Xpirit-Assessments/assessment-joostvoskuil \
  --signer-workflow github.com/Xebia-Xpirit-Assessments/assessment-joostvoskuil/.github/workflows/template-publish-service.yml \
  --cert-oidc-issuer https://token.actions.githubusercontent.com \
  --source-digest <commit-sha>
```

`--signer-workflow` takes `[host/]<owner>/<repo>/<path>/<to>/<workflow>` — no `https://` scheme. This repository's attestations are signed with the Sigstore public-good instance; do not add `--no-public-good`.

Evidence consists of the pull request and review, required-check results, protected Environment approval, immutable image digest, GitHub attestation URLs, SBOM, retained `signed-build-evidence-*` Actions artifact, and Azure deployment logs. Keep these records according to the organization's approved retention schedule; the 365-day workflow artifact retention is the repository baseline.

## Administrator controls outside this repository

GitHub and Azure administrators must separately verify and retain evidence that:

- the `main` ruleset requires pull requests, required checks, workflow/infrastructure CODEOWNER review, and prevents force pushes and bypasses;
- the `production` Environment has required reviewers and deployment-branch restrictions;
- GitHub Enterprise audit-log and Actions-artifact retention meet the approved retention schedule;
- the shared publisher identity has `AcrPush`, while Staging and Production deployment identities and workload identities have only the required `AcrPull` access; and
- ACR lifecycle and retention policies preserve previously attested image digests for the approved rollback period.

The engineering owner reviews workflow changes and failed verification events. The platform owner maintains GitHub rulesets, Entra federated credentials, Azure RBAC, ACR retention, and audit-log settings. Any emergency bypass requires an approved incident/change record and a retrospective review.