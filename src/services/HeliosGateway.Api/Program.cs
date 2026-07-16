using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Security.Api", input => new CoreSecurityApiCapability.CoreSecurityApiCapability().Execute(input), seed => new CoreSecurityApiCapability.CoreSecurityApiCapability().Score(seed)),
    new SharedDependency("Identity.Tokens.Api", input => new IdentityTokensApiCapability.IdentityTokensApiCapability().Execute(input), seed => new IdentityTokensApiCapability.IdentityTokensApiCapability().Score(seed)),
    new SharedDependency("Geo.Location.Api", input => new GeoLocationApiCapability.GeoLocationApiCapability().Execute(input), seed => new GeoLocationApiCapability.GeoLocationApiCapability().Score(seed)),
    new SharedDependency("Resilience.Policy.Api", input => new ResiliencePolicyApiCapability.ResiliencePolicyApiCapability().Execute(input), seed => new ResiliencePolicyApiCapability.ResiliencePolicyApiCapability().Score(seed)),
    new SharedDependency("Cache.Distributed.Api", input => new CacheDistributedApiCapability.CacheDistributedApiCapability().Execute(input), seed => new CacheDistributedApiCapability.CacheDistributedApiCapability().Score(seed)),
    new SharedDependency("FeatureFlags.Client.Api", input => new FeatureFlagsClientApiCapability.FeatureFlagsClientApiCapability().Execute(input), seed => new FeatureFlagsClientApiCapability.FeatureFlagsClientApiCapability().Score(seed)),
    new SharedDependency("Queue.Retry.Api", input => new QueueRetryApiCapability.QueueRetryApiCapability().Execute(input), seed => new QueueRetryApiCapability.QueueRetryApiCapability().Score(seed)),
    new SharedDependency("Observability.Metrics.Api", input => new ObservabilityMetricsApiCapability.ObservabilityMetricsApiCapability().Execute(input), seed => new ObservabilityMetricsApiCapability.ObservabilityMetricsApiCapability().Score(seed))
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
