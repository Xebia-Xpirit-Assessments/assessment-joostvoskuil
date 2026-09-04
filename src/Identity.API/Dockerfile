# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY Directory.Build.props Directory.Build.targets Directory.Packages.props global.json nuget.config ./
COPY src/Identity.API/Identity.API.csproj src/Identity.API/
COPY src/eShop.ServiceDefaults/eShop.ServiceDefaults.csproj src/eShop.ServiceDefaults/
RUN dotnet restore src/Identity.API/Identity.API.csproj
COPY . .
RUN dotnet publish src/Identity.API/Identity.API.csproj --configuration Release --output /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Identity.API.dll"]
