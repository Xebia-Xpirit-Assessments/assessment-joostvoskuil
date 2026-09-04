FROM mcr.microsoft.com/devcontainers/dotnet:1-8.0-bookworm

# This repository uses the .NET 8 Aspire workload model.
USER root
RUN find /etc/apt/sources.list.d -type f -iname '*yarn*' -delete \
	&& dotnet workload install aspire
USER vscode
