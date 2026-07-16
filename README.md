# Veracode .NET Microservices Lab

Laboratorio para testar empacotamento SAST da Veracode em uma arquitetura de microservicos .NET 8.

## Estrutura

- 9 microservicos ASP.NET Core Minimal API com nomes variados.
- 41 shared APIs/bibliotecas com nomes variados.
- 5 shared APIs sao dedicadas e nao sao referenciadas por nenhum service.
- Cada microservico referencia um subconjunto aleatorio/estavel de shared APIs.
- Alguns shared APIs sao repetidos entre services de proposito, para validar a deduplicacao do pacote Veracode.
- O pacote agregado deduplica DLLs internas compartilhadas.
- Cada microservico possui um `Dockerfile` proprio que publica seu respectivo `.csproj` e fecha uma imagem runtime.

## Topologia

- AtlasFuel.Api: Core.Contracts.Api, Core.Security.Api, Domain.Fuel.Api, Domain.Fleet.Api, Pricing.Rules.Api, Observability.Audit.Api, Queue.Messaging.Api
- NimbusInvoice.Api: Core.Contracts.Api, Core.Validation.Api, Domain.Invoice.Api, Pricing.Tax.Api, Integration.Sap.Api, Document.Rendering.Api, Reporting.Export.Api, Queue.Retry.Api
- OrionLedger.Api: Data.Abstractions.Api, Data.SqlBridge.Api, Domain.Payment.Api, Integration.Bank.Api, Reconciliation.Engine.Api, Reporting.Query.Api
- VertexPricing.Api: Core.Contracts.Api, Core.Validation.Api, Pricing.Rules.Api, Pricing.Tax.Api, FeatureFlags.Client.Api, Cache.Local.Api
- AstraConciliation.Api: Data.Abstractions.Api, Domain.Invoice.Api, Domain.Payment.Api, Reconciliation.Engine.Api, Reconciliation.Matching.Api, Observability.Tracing.Api, Queue.Messaging.Api
- PulseTelemetry.Api: Observability.Audit.Api, Observability.Metrics.Api, Observability.Tracing.Api, Queue.Messaging.Api, Cache.Distributed.Api
- ZenithApproval.Api: Core.Security.Api, Identity.Claims.Api, Identity.Tokens.Api, Workflow.Approval.Api, Workflow.Notification.Api, Integration.Email.Api
- NovaDocument.Api: Core.Contracts.Api, Document.Rendering.Api, Document.Signature.Api, Integration.Storage.Api, Domain.Customer.Api, Reporting.Export.Api
- HeliosGateway.Api: Core.Security.Api, Identity.Tokens.Api, Geo.Location.Api, Resilience.Policy.Api, Cache.Distributed.Api, FeatureFlags.Client.Api, Queue.Retry.Api, Observability.Metrics.Api

## Comandos

```bash
./scripts/build.sh
./scripts/create-sca-aggregate-project.sh
./scripts/package-all-services-for-veracode.sh
./scripts/veracode-cli-scans.sh
./scripts/build-service-images.sh
```

## Cenarios Vulneraveis

Este repositorio contem vulnerabilidades intencionais para validar achados no Veracode.

SAST:

- `src/services/AtlasFuel.Api/Program.cs`: SQL dinamico com entrada externa.
- `src/services/AtlasFuel.Api/Program.cs`: execucao de comando usando parametro HTTP.
- `src/services/AtlasFuel.Api/Program.cs`: leitura de arquivo com path controlado pelo usuario.
- `src/services/AtlasFuel.Api/Program.cs`: uso de MD5.
- `src/shared/Core.Security.Api/CoreSecurityApiCapability.cs`: segredo hardcoded e SHA1.

SCA:

- `src/services/AtlasFuel.Api/AtlasFuel.Api.csproj`: pacotes NuGet antigos para teste, incluindo bibliotecas de JSON, HTTP, ZIP, AWS SDK, log e YAML.
- `src/services/HeliosGateway.Api/HeliosGateway.Api.csproj`: pacotes NuGet antigos para teste.
- `src/shared/Core.Security.Api/Core.Security.Api.csproj`: pacotes NuGet antigos de JWT, HTTP e criptografia.

IaC:

- `infra/terraform`: deploy Kubernetes por Terraform com configuracoes inseguras intencionais, como container privilegiado, root user, `hostNetwork`, `hostPID`, `hostIPC`, `hostPath`, token de service account montado automaticamente, seccomp/AppArmor unconfined, secrets hardcoded em env var e Service `LoadBalancer`.
- `infra/terraform/vulnerable-lab`: cenarios extras vulneraveis para IaC, incluindo AWS S3 publico, Security Group aberto, EC2 com IMDSv1 e disco sem criptografia, Azure Storage publico com TLS antigo, VM com senha hardcoded e Kubernetes com `cluster-admin`, `privileged`, `hostPath` e secrets hardcoded.
- `src/services/*/Dockerfile`: parametros inseguros intencionais para laboratorio, como secrets em `ENV`, `USER root`, `EXPOSE 22` e permissao `777` em `/app`.

## GitHub Actions

- `.github/workflows/all-microservices-veracode.yaml`: pipeline unica para a aplicacao inteira.

O script `scripts/package-all-services-for-veracode.sh` descobre a API principal informada em `APP_PROJECTS`, os microservicos em `SERVICE_ROOT` e todos os projetos compartilhados em `SHARED_ROOT`. Ele ignora diretorios de build/cache como `bin`, `obj`, `Debug`, `Release`, `publish`, `TestResults`, `.vs`, `.git` e `node_modules`, publica cada API e cada projeto shared, copia cada DLL/PDB interna apenas uma vez pelo nome do arquivo e cria o `veracode-upload.zip`. Antes de fechar o ZIP, o script remove qualquer arquivo que nao seja `.dll` ou `.pdb` e falha se detectar nomes duplicados ou paths excluidos no pacote.

Observacao: no SAST da Veracode para .NET, o pacote enviado deve conter os assemblies compilados (`.dll`/`.pdb`), nao os `.csproj`. Por isso o workflow gera a pasta `veracode-evidence/` com `service-projects.txt`, `shared-projects.txt`, `internal-assemblies.txt`, `sast-package-files.txt`, `sast-package-file-names.txt`, `duplicate-file-names.txt` e `excluded-path-violations.txt` para evidenciar todos os projetos incluidos, preservar os nomes originais e provar que nao ha arquivos duplicados nem paths indevidos no scan.

A pipeline executa:

- QA: build dos projetos e geracao do `veracode-upload.zip`.
- SAST: Upload And Scan com `veracode/veracode-uploadandscan-action` usando o ZIP gerado no QA.
- SCA: Agent-Based Scan executado diretamente pelo agente `ci.sh` com `--skip-vms`. Para evitar o erro `Workspace has reached maximum number of projects`, o workflow gera `sca-scan/VeracodeSca.Aggregate.csproj` com os `PackageReference` unicos de todos os projetos e escaneia somente essa pasta, criando um unico projeto SCA no workspace. O workspace vem do proprio `SRCCLR_API_TOKEN`; nao informe `SRCCLR_WORKSPACE_SLUG` quando usar token de nivel workspace. O workflow tambem remove variaveis `SRCCLR_WORKSPACE*` antes do scan para evitar sobrescrita herdada de variable groups.
- IaC: Veracode CLI via `scripts/veracode-cli-scans.sh`, apontando para o repositorio inteiro para incluir Terraform e Dockerfiles.
- Docker: build das imagens somente depois dos scans Veracode.

Configure estes secrets no GitHub:

- `VERACODE_API_ID`
- `VERACODE_API_KEY`
- `SRCCLR_API_TOKEN`

Configuracoes opcionais via GitHub Actions Variables:

- `VERACODE_APP_NAME`: nome do profile na Veracode. Se nao informado, usa `github.repository`.
- `APP_PROJECTS`: lista opcional de `.csproj` da API principal, separada por espaco.
- `SERVICE_ROOT`: raiz dos microservicos. Padrao: `src/services`.
- `SHARED_ROOT`: raiz dos projetos compartilhados. Padrao: `src/shared`.
- `TARGET_FRAMEWORK`: framework de publish. Padrao: `net8.0`.
- `SCA_FAIL_ON_WORKSPACE_LIMIT`: se `true`, falha a pipeline quando o workspace SCA atingir o limite de projetos. Padrao: `false`, para laboratorios com workspace cheio.

## Azure DevOps

- `azure-pipelines.yml`: pipeline unica equivalente ao GitHub Actions, adaptada para Azure DevOps.

A pipeline executa os mesmos passos: QA/package, SAST Upload And Scan, SCA, IaC e Docker build somente depois dos scans. O SAST usa o container `veracode/api-wrapper-java`, entao nao depende de extensao do Marketplace do Azure DevOps.

Para hospedar no Azure Repos:

```bash
git init
git add .
git commit -m "Add Veracode microservices lab"
git branch -M main
git remote add origin https://dev.azure.com/<ORG>/<PROJECT>/_git/<REPO>
git push -u origin main
```

No Azure DevOps, crie a pipeline em `Pipelines > New pipeline > Azure Repos Git > Existing Azure Pipelines YAML file` e selecione `/azure-pipelines.yml`.

Ao criar a pipeline no Azure DevOps, selecione o arquivo `azure-pipelines.yml` na raiz do repositorio e configure estas variaveis secretas em Pipeline variables ou Library variable group:

- `VERACODE_API_ID`
- `VERACODE_API_KEY`
- `SRCCLR_API_TOKEN`

Variaveis opcionais no Azure DevOps:

- `VERACODE_APP_NAME`: nome do profile na Veracode. Padrao: `$(Build.Repository.Name)`.
- `APP_PROJECTS`: lista opcional de `.csproj` da API principal, separada por espaco.
- `SERVICE_ROOT`: raiz dos microservicos. Padrao: `src/services`.
- `SHARED_ROOT`: raiz dos projetos compartilhados. Padrao: `src/shared`.
- `TARGET_FRAMEWORK`: framework de publish. Padrao: `net8.0`.
- `SCA_FAIL_ON_WORKSPACE_LIMIT`: se `true`, falha a pipeline quando o workspace SCA atingir o limite de projetos. Padrao: `false`, para laboratorios com workspace cheio.

Configuracoes opcionais via variaveis de ambiente dos scripts:

- `SERVICE_ROOT`: raiz dos microservicos. Padrao: `src/services`.
- `SHARED_ROOT`: raiz dos projetos compartilhados. Padrao: `src/shared`.
- `APP_PROJECTS`: lista opcional de `.csproj` da API principal, separada por espaco.
- `TARGET_FRAMEWORK`: framework de publish. Padrao: `net8.0`.
- `IMAGE_PREFIX`: prefixo das imagens Docker. Padrao: nome da pasta do repositorio.
- `IMAGE_TAG`: tag das imagens Docker. Padrao: `local`.

Configuracoes obrigatorias do Terraform:

- `services`: lista dos microservicos que serao implantados.
- `image_registry`: registry/prefixo das imagens.

Observacao para laboratorio: o Terraform contem secrets hardcoded de proposito em `infra/terraform/main.tf`, para que o scan de IaC/secret scanning consiga identificar esse tipo de problema.
