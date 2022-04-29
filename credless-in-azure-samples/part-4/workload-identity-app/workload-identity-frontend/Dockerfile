#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["workload-identity-frontend.csproj", "."]
RUN dotnet restore "./workload-identity-frontend.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "workload-identity-frontend.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "workload-identity-frontend.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "workload-identity-frontend.dll"]