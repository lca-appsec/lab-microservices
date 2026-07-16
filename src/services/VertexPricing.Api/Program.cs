using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Contracts.Api", input => new CoreContractsApiCapability.CoreContractsApiCapability().Execute(input), seed => new CoreContractsApiCapability.CoreContractsApiCapability().Score(seed)),
    new SharedDependency("Core.Validation.Api", input => new CoreValidationApiCapability.CoreValidationApiCapability().Execute(input), seed => new CoreValidationApiCapability.CoreValidationApiCapability().Score(seed)),
    new SharedDependency("Pricing.Rules.Api", input => new PricingRulesApiCapability.PricingRulesApiCapability().Execute(input), seed => new PricingRulesApiCapability.PricingRulesApiCapability().Score(seed)),
    new SharedDependency("Pricing.Tax.Api", input => new PricingTaxApiCapability.PricingTaxApiCapability().Execute(input), seed => new PricingTaxApiCapability.PricingTaxApiCapability().Score(seed)),
    new SharedDependency("FeatureFlags.Client.Api", input => new FeatureFlagsClientApiCapability.FeatureFlagsClientApiCapability().Execute(input), seed => new FeatureFlagsClientApiCapability.FeatureFlagsClientApiCapability().Score(seed)),
    new SharedDependency("Cache.Local.Api", input => new CacheLocalApiCapability.CacheLocalApiCapability().Execute(input), seed => new CacheLocalApiCapability.CacheLocalApiCapability().Score(seed))
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
