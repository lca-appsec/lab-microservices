# Veracode .NET Microservices Lab

Laboratorio para testar empacotamento SAST da Veracode em uma arquitetura de microservicos .NET 8.

## Estrutura

- 9 microservicos ASP.NET Core Minimal API com nomes variados.
- 36 shared APIs/bibliotecas com nomes variados.
- Cada microservico referencia um subconjunto aleatorio/estavel de shared APIs.
- O pacote agregado deduplica DLLs internas compartilhadas.

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
./scripts/package-duplicated.sh
./scripts/package-deduplicated.sh
./scripts/package-all-services-for-veracode.sh
./scripts/count-dlls.sh
```

## GitHub Actions

- `.github/workflows/all-microservices-veracode.yml`: scan agregado deduplicado.
- `.github/workflows/*-veracode.yml`: uma pipeline por microservico.
