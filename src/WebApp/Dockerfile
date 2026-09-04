# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY Directory.Build.props Directory.Build.targets Directory.Packages.props global.json nuget.config ./
COPY src/WebApp/WebApp.csproj src/WebApp/
COPY src/WebAppComponents/WebAppComponents.csproj src/WebAppComponents/
COPY src/eShop.ServiceDefaults/eShop.ServiceDefaults.csproj src/eShop.ServiceDefaults/
COPY src/EventBus/EventBus.csproj src/EventBus/
COPY src/EventBusRabbitMQ/EventBusRabbitMQ.csproj src/EventBusRabbitMQ/
RUN dotnet restore src/WebApp/WebApp.csproj
COPY . .
RUN dotnet publish src/WebApp/WebApp.csproj --configuration Release --output /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
EXPOSE 8080
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "WebApp.dll"]
