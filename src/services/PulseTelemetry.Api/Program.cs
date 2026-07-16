using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Observability.Audit.Api", input => new ObservabilityAuditApiCapability.ObservabilityAuditApiCapability().Execute(input), seed => new ObservabilityAuditApiCapability.ObservabilityAuditApiCapability().Score(seed)),
    new SharedDependency("Observability.Metrics.Api", input => new ObservabilityMetricsApiCapability.ObservabilityMetricsApiCapability().Execute(input), seed => new ObservabilityMetricsApiCapability.ObservabilityMetricsApiCapability().Score(seed)),
    new SharedDependency("Observability.Tracing.Api", input => new ObservabilityTracingApiCapability.ObservabilityTracingApiCapability().Execute(input), seed => new ObservabilityTracingApiCapability.ObservabilityTracingApiCapability().Score(seed)),
    new SharedDependency("Queue.Messaging.Api", input => new QueueMessagingApiCapability.QueueMessagingApiCapability().Execute(input), seed => new QueueMessagingApiCapability.QueueMessagingApiCapability().Score(seed)),
    new SharedDependency("Cache.Distributed.Api", input => new CacheDistributedApiCapability.CacheDistributedApiCapability().Execute(input), seed => new CacheDistributedApiCapability.CacheDistributedApiCapability().Score(seed))
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
