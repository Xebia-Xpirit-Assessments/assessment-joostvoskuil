#!/usr/bin/env bash

set -euo pipefail

echo "Resetting ASP.NET Core HTTPS development certificate..."
# Always clean and regenerate: a stale/corrupt cert left over from a prior
# container session is a known cause of Aspire DCP SSL handshake failures
# ("unexpected EOF" / "UntrustedRoot") on the internal DCP<->AppHost channel.
# See https://github.com/dotnet/eShop/issues/530 and
# https://github.com/dotnet/eShop/issues/777.
dotnet dev-certs https --clean
dotnet dev-certs https --trust || dotnet dev-certs https
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
