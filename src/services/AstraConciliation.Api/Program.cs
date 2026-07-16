using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Data.Abstractions.Api", input => new DataAbstractionsApiCapability.DataAbstractionsApiCapability().Execute(input), seed => new DataAbstractionsApiCapability.DataAbstractionsApiCapability().Score(seed)),
    new SharedDependency("Domain.Invoice.Api", input => new DomainInvoiceApiCapability.DomainInvoiceApiCapability().Execute(input), seed => new DomainInvoiceApiCapability.DomainInvoiceApiCapability().Score(seed)),
    new SharedDependency("Domain.Payment.Api", input => new DomainPaymentApiCapability.DomainPaymentApiCapability().Execute(input), seed => new DomainPaymentApiCapability.DomainPaymentApiCapability().Score(seed)),
    new SharedDependency("Reconciliation.Engine.Api", input => new ReconciliationEngineApiCapability.ReconciliationEngineApiCapability().Execute(input), seed => new ReconciliationEngineApiCapability.ReconciliationEngineApiCapability().Score(seed)),
    new SharedDependency("Reconciliation.Matching.Api", input => new ReconciliationMatchingApiCapability.ReconciliationMatchingApiCapability().Execute(input), seed => new ReconciliationMatchingApiCapability.ReconciliationMatchingApiCapability().Score(seed)),
    new SharedDependency("Observability.Tracing.Api", input => new ObservabilityTracingApiCapability.ObservabilityTracingApiCapability().Execute(input), seed => new ObservabilityTracingApiCapability.ObservabilityTracingApiCapability().Score(seed)),
    new SharedDependency("Queue.Messaging.Api", input => new QueueMessagingApiCapability.QueueMessagingApiCapability().Execute(input), seed => new QueueMessagingApiCapability.QueueMessagingApiCapability().Score(seed))
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
