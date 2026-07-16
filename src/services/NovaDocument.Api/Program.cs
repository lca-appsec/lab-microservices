using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Contracts.Api", input => new CoreContractsApiCapability.CoreContractsApiCapability().Execute(input), seed => new CoreContractsApiCapability.CoreContractsApiCapability().Score(seed)),
    new SharedDependency("Document.Rendering.Api", input => new DocumentRenderingApiCapability.DocumentRenderingApiCapability().Execute(input), seed => new DocumentRenderingApiCapability.DocumentRenderingApiCapability().Score(seed)),
    new SharedDependency("Document.Signature.Api", input => new DocumentSignatureApiCapability.DocumentSignatureApiCapability().Execute(input), seed => new DocumentSignatureApiCapability.DocumentSignatureApiCapability().Score(seed)),
    new SharedDependency("Integration.Storage.Api", input => new IntegrationStorageApiCapability.IntegrationStorageApiCapability().Execute(input), seed => new IntegrationStorageApiCapability.IntegrationStorageApiCapability().Score(seed)),
    new SharedDependency("Domain.Customer.Api", input => new DomainCustomerApiCapability.DomainCustomerApiCapability().Execute(input), seed => new DomainCustomerApiCapability.DomainCustomerApiCapability().Score(seed)),
    new SharedDependency("Reporting.Export.Api", input => new ReportingExportApiCapability.ReportingExportApiCapability().Execute(input), seed => new ReportingExportApiCapability.ReportingExportApiCapability().Score(seed))
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
