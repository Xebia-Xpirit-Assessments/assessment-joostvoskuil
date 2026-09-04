---
name: prepare-local-eshop-environment
description: 'Prepare and validate a local development environment for this .NET 8 eShop application on macOS, Linux, or Windows. Use when setting up the repository, fixing dotnet restore or dotnet run failures, installing the Aspire workload, troubleshooting Docker, or validating prerequisites before local development.'
argument-hint: 'Optional: operating system and the command or error that is failing'
user-invocable: true
---

# Prepare the local eShop environment

## Purpose

Set up and validate the tools required to build and run this repository locally. This repository is an older .NET 8 application using the .NET Aspire 8 workload, Docker-based dependencies, LibMan, and centrally managed NuGet packages.

Do not upgrade framework, Aspire, or package versions as part of environment preparation unless the user explicitly requests an upgrade. Prefer fixing the local environment first.

## Repository requirements

- .NET SDK 8.x. The repository's `global.json` pins the SDK to `8.0.200` and uses `latestFeature` roll-forward, so a newer 8.0 feature-band SDK is acceptable. Do not use .NET 10 for this application.
- The Aspire workload compatible with the .NET 8 SDK.
- Docker Desktop, running before starting the AppHost.
- NuGet access to `https://api.nuget.org/v3/index.json`.
- On Apple Silicon, Rosetta 2 may be required by `grpc-tools`.
- Optional: .NET MAUI workload only when working on `src/ClientApp`.

## Preparation procedure

### Codespaces / Dev Container

For GitHub Codespaces or VS Code Dev Containers, reopen the repository in the configured container. The `.devcontainer/devcontainer.json` configuration provides:

- .NET 8 and the Aspire workload.
- Docker-in-Docker for Aspire-managed PostgreSQL, RabbitMQ, and Redis containers.
- Node.js 20 and npm for the Playwright end-to-end tests.
- GitHub Copilot, C# Dev Kit, C#, and Docker extensions.

After the container is created, `postCreateCommand` restores `eShop.Web.slnf` and installs the npm dependencies automatically. Validate Docker with `docker info` before starting the AppHost.

### 1. Check the repository and SDK

Run commands from the repository root:

```sh
dotnet --version
dotnet --list-sdks
dotnet --info
```

The selected version must be `8.0.x`. If the output is `10.x`, check `global.json` and install a .NET 8 SDK. Do not solve this by changing the project to .NET 10.

If no .NET 8 SDK is installed, install the current .NET 8 SDK from the official .NET download page or the platform package manager, then restart the terminal and VS Code.

### 2. Install and validate Aspire

Check installed workloads:

```sh
dotnet workload list
```

If `aspire` is missing, restore or install it using the .NET 8 SDK:

```sh
dotnet workload restore src/eShop.AppHost/eShop.AppHost.csproj
```

If workload restore reports inadequate permissions on macOS or Linux, rerun the workload installation with administrator privileges as appropriate for the operating system. Do not run the application itself with `sudo`.

If `dotnet workload restore eShop.Web.slnf` says it cannot find a project, target `src/eShop.AppHost/eShop.AppHost.csproj` directly.

### 3. Check Docker

Start Docker Desktop and wait until it reports that the engine is running. Validate the engine before running Aspire:

```sh
docker info
docker version
```

A Docker CLI installation alone is not sufficient. If `docker info` cannot connect to the daemon, start Docker Desktop and retry. The AppHost provisions dependencies such as PostgreSQL, RabbitMQ, and Redis through Aspire.

### 4. Restore and build

Restore the web solution filter:

```sh
dotnet restore eShop.Web.slnf
```

Build the AppHost:

```sh
dotnet build src/eShop.AppHost/eShop.AppHost.csproj
```

Run the application:

```sh
dotnet run --project src/eShop.AppHost/eShop.AppHost.csproj
```

Use the dashboard URL printed by Aspire, normally a localhost URL containing a login token.

## Troubleshooting guide

### `NETSDK1228` — deprecated Aspire workload

Cause: the project was evaluated by a newer SDK, commonly .NET 10, while this repository uses the .NET 8 Aspire workload model.

Resolution:

1. Install a .NET 8 SDK.
2. Confirm `dotnet --version` reports `8.0.x`.
3. Keep `global.json` constrained to .NET 8.
4. Install/restore the Aspire workload using the .NET 8 SDK.

### `NETSDK1147` — required workload `aspire`

Cause: the correct .NET SDK is selected, but the Aspire workload is not installed.

Resolution: run the AppHost-targeted workload restore from the repository root, handling administrator permissions if requested.

### `LIB002` or `LIB018` for Bootstrap

The Bootstrap entry is in `src/Identity.API/libman.json`. Its provider and file paths must agree:

- `cdnjs` uses paths such as `css/bootstrap.min.css` and `js/bootstrap.min.js`.
- npm/unpkg package layouts commonly use `dist/css/...` and `dist/js/...`.

If LibMan cannot resolve the configured provider, use the provider and paths already validated in the repository rather than mixing layouts.

### `NU1901`, `NU1902`, or `NU1903`

These are NuGet vulnerability audit findings. They may appear repeatedly because shared projects reference the affected packages transitively. They are separate from SDK, Aspire, Docker, and LibMan setup.

Do not hide or suppress these warnings as the normal environment fix. Track package updates separately in `Directory.Packages.props`, test compatibility, and prefer patched versions. In particular, review the pinned versions of:

- `OpenTelemetry.Exporter.OpenTelemetryProtocol`
- `AutoMapper`
- `Duende.IdentityServer`

### AppHost exits before showing the dashboard

Check, in order:

1. `dotnet --version` is `8.0.x`.
2. `dotnet workload list` includes `aspire`.
3. `docker info` succeeds.
4. Docker Desktop is fully started.
5. The build succeeds without errors.
6. No required localhost ports are already occupied.

Capture the complete output from `dotnet run`; do not infer a Docker failure from the exit code alone.

## Final validation checklist

- [ ] `dotnet --version` reports .NET 8.
- [ ] `dotnet workload list` includes `aspire`.
- [ ] Docker Desktop is running.
- [ ] `docker info` succeeds.
- [ ] `dotnet restore eShop.Web.slnf` completes without errors.
- [ ] `dotnet build src/eShop.AppHost/eShop.AppHost.csproj` completes without errors.
- [ ] `dotnet run --project src/eShop.AppHost/eShop.AppHost.csproj` reaches the Aspire dashboard output.
