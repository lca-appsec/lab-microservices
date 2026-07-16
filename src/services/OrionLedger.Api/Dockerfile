FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

ARG SERVICE_PROJECT
ARG SERVICE_ASSEMBLY
ARG TARGET_FRAMEWORK=net8.0

COPY . .
RUN dotnet publish "$SERVICE_PROJECT" \
    -c Release \
    -f "$TARGET_FRAMEWORK" \
    -o /app/publish \
    -p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

ARG SERVICE_ASSEMBLY
ENV SERVICE_ASSEMBLY=$SERVICE_ASSEMBLY
ENV ASPNETCORE_URLS=http://+:8080
ENV LAB_ADMIN_PASSWORD=ContainerPassword123!
ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
ENV AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

USER root
EXPOSE 22 8080

COPY --from=build /app/publish .
RUN chmod -R 777 /app
ENTRYPOINT ["sh", "-c", "dotnet ${SERVICE_ASSEMBLY}.dll"]
