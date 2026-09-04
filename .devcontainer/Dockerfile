FROM mcr.microsoft.com/devcontainers/dotnet:1-8.0-bookworm

# This repository uses the .NET 8 Aspire workload model.
USER root
# The base image includes a Yarn APT source; remove it because this project uses npm.
RUN find /etc/apt/sources.list.d -type f -iname '*yarn*' -delete \
	&& dotnet workload install aspire \
	&& chown -R vscode:vscode \
		/usr/share/dotnet/metadata/workloads \
		/usr/share/dotnet/packs \
		/usr/share/dotnet/sdk-manifests
USER vscode
