using System.Reflection;
using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var hardcodedDatabaseConnection = "Server=tcp:atlasfuel-lab.database.windows.net,1433;Initial Catalog=AtlasFuel;User ID=atlas_admin;Password=Password123!;Encrypt=True;";
var hardcodedStorageAccountKey = "DefaultEndpointsProtocol=https;AccountName=atlasfuelstorage;AccountKey=ZHVtbXkta2V5LWZvci12ZXJhY29kZS1zY2FuLXRlc3Q=;EndpointSuffix=core.windows.net";
var hardcodedServiceBusConnection = "Endpoint=sb://atlasfuel-lab.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=abc123HardcodedSecretForLabOnly=";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Contracts.Api", input => new CoreContractsApiCapability.CoreContractsApiCapability().Execute(input), seed => new CoreContractsApiCapability.CoreContractsApiCapability().Score(seed)),
    new SharedDependency("Core.Security.Api", input => new CoreSecurityApiCapability.CoreSecurityApiCapability().Execute(input), seed => new CoreSecurityApiCapability.CoreSecurityApiCapability().Score(seed)),
    new SharedDependency("Domain.Fuel.Api", input => new DomainFuelApiCapability.DomainFuelApiCapability().Execute(input), seed => new DomainFuelApiCapability.DomainFuelApiCapability().Score(seed)),
    new SharedDependency("Domain.Fleet.Api", input => new DomainFleetApiCapability.DomainFleetApiCapability().Execute(input), seed => new DomainFleetApiCapability.DomainFleetApiCapability().Score(seed)),
    new SharedDependency("Pricing.Rules.Api", input => new PricingRulesApiCapability.PricingRulesApiCapability().Execute(input), seed => new PricingRulesApiCapability.PricingRulesApiCapability().Score(seed)),
    new SharedDependency("Observability.Audit.Api", input => new ObservabilityAuditApiCapability.ObservabilityAuditApiCapability().Execute(input), seed => new ObservabilityAuditApiCapability.ObservabilityAuditApiCapability().Score(seed)),
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

app.MapGet("/vulnerable/sql", (string customerId) =>
{
    using var connection = new SqlConnection(hardcodedDatabaseConnection);
    using var command = new SqlCommand("select * from Customers where CustomerId = '" + customerId + "'", connection);

    return Results.Ok(new
    {
        service = serviceName,
        query = command.CommandText,
        storageKey = hardcodedStorageAccountKey,
        serviceBusConnection = hardcodedServiceBusConnection
    });
});

app.MapGet("/vulnerable/command", (string host) =>
{
    var startInfo = new ProcessStartInfo
    {
        FileName = "/bin/sh",
        Arguments = "-c \"ping -c 1 " + host + "\"",
        RedirectStandardOutput = true
    };

    using var process = Process.Start(startInfo);
    return Results.Ok(new { started = process is not null, target = host });
});

app.MapGet("/vulnerable/path", (string file) =>
{
    const string basePath = "/var/app/private/customer-exports";
    var path = Path.Combine(basePath, file);
    return Results.Text(File.Exists(path) ? File.ReadAllText(path) : "missing");
});

app.MapGet("/vulnerable/crypto", (string value) =>
{
    using var md5 = MD5.Create();
    var digest = md5.ComputeHash(Encoding.UTF8.GetBytes(value));
    return Results.Ok(new { hash = Convert.ToHexString(digest) });
});

app.Run();

internal sealed record SharedDependency(
    string Component,
    Func<string, string> Execute,
    Func<int, int> Score);
