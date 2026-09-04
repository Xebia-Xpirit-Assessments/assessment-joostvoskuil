#!/usr/bin/env bash

set -euo pipefail

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
