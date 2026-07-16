using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Data.Abstractions.Api", input => new DataAbstractionsApiCapability.DataAbstractionsApiCapability().Execute(input), seed => new DataAbstractionsApiCapability.DataAbstractionsApiCapability().Score(seed)),
    new SharedDependency("Data.SqlBridge.Api", input => new DataSqlBridgeApiCapability.DataSqlBridgeApiCapability().Execute(input), seed => new DataSqlBridgeApiCapability.DataSqlBridgeApiCapability().Score(seed)),
    new SharedDependency("Domain.Payment.Api", input => new DomainPaymentApiCapability.DomainPaymentApiCapability().Execute(input), seed => new DomainPaymentApiCapability.DomainPaymentApiCapability().Score(seed)),
    new SharedDependency("Integration.Bank.Api", input => new IntegrationBankApiCapability.IntegrationBankApiCapability().Execute(input), seed => new IntegrationBankApiCapability.IntegrationBankApiCapability().Score(seed)),
    new SharedDependency("Reconciliation.Engine.Api", input => new ReconciliationEngineApiCapability.ReconciliationEngineApiCapability().Execute(input), seed => new ReconciliationEngineApiCapability.ReconciliationEngineApiCapability().Score(seed)),
    new SharedDependency("Reporting.Query.Api", input => new ReportingQueryApiCapability.ReportingQueryApiCapability().Execute(input), seed => new ReportingQueryApiCapability.ReportingQueryApiCapability().Score(seed))
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
