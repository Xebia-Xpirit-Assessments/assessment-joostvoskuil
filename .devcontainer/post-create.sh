#!/usr/bin/env bash

set -euo pipefail

echo "Checking ASP.NET Core HTTPS development certificate..."
if ! dotnet dev-certs https --check >/dev/null 2>&1; then
	dotnet dev-certs https
fi
echo "ASP.NET Core HTTPS development certificate ready."

echo "Removing host-generated .NET build artifacts..."
find src tests -type d \( -name bin -o -name obj \) -prune -exec rm -rf {} +
echo "Host-generated build artifacts removed."

echo "Restoring .NET dependencies..."
dotnet restore eShop.Web.slnf
echo ".NET restore complete."

echo "Installing npm dependencies..."
npm ci
echo "npm setup complete."

echo
echo "Development environment setup complete."
echo "To start the application, run:"
echo "  dotnet run --project src/eShop.AppHost/eShop.AppHost.csproj"
