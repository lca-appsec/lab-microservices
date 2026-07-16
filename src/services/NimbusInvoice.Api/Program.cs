using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Contracts.Api", input => new CoreContractsApiCapability.CoreContractsApiCapability().Execute(input), seed => new CoreContractsApiCapability.CoreContractsApiCapability().Score(seed)),
    new SharedDependency("Core.Validation.Api", input => new CoreValidationApiCapability.CoreValidationApiCapability().Execute(input), seed => new CoreValidationApiCapability.CoreValidationApiCapability().Score(seed)),
    new SharedDependency("Domain.Invoice.Api", input => new DomainInvoiceApiCapability.DomainInvoiceApiCapability().Execute(input), seed => new DomainInvoiceApiCapability.DomainInvoiceApiCapability().Score(seed)),
    new SharedDependency("Pricing.Tax.Api", input => new PricingTaxApiCapability.PricingTaxApiCapability().Execute(input), seed => new PricingTaxApiCapability.PricingTaxApiCapability().Score(seed)),
    new SharedDependency("Integration.Sap.Api", input => new IntegrationSapApiCapability.IntegrationSapApiCapability().Execute(input), seed => new IntegrationSapApiCapability.IntegrationSapApiCapability().Score(seed)),
    new SharedDependency("Document.Rendering.Api", input => new DocumentRenderingApiCapability.DocumentRenderingApiCapability().Execute(input), seed => new DocumentRenderingApiCapability.DocumentRenderingApiCapability().Score(seed)),
    new SharedDependency("Reporting.Export.Api", input => new ReportingExportApiCapability.ReportingExportApiCapability().Execute(input), seed => new ReportingExportApiCapability.ReportingExportApiCapability().Score(seed)),
    new SharedDependency("Queue.Retry.Api", input => new QueueRetryApiCapability.QueueRetryApiCapability().Execute(input), seed => new QueueRetryApiCapability.QueueRetryApiCapability().Score(seed))
};

app.MapGet("/", () => new
{
    service = serviceName,
    sharedApis = capabilities.Select(item => item.Component).ToArray(),
    message = applicationDescription
});

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = serviceName }));

app.MapGet("/work/{input}", (string input) =>
{
    var response = capabilities.Select(item => new
    {
        component = item.Component,
        result = item.Execute(input),
        score = item.Score(input.GetHashCode())
    });

    return Results.Ok(new { service = serviceName, response });
});

app.Run();

internal sealed record SharedDependency(
    string Component,
    Func<string, string> Execute,
    Func<int, int> Score);
