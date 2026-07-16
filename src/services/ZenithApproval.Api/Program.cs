using System.Reflection;
var builder = WebApplication.CreateBuilder(args);
var serviceName = builder.Configuration["ServiceName"] ?? Assembly.GetExecutingAssembly().GetName().Name ?? "service";
var applicationDescription = builder.Configuration["ApplicationDescription"] ?? $"{serviceName} dependency lab";
var app = builder.Build();

var capabilities = new SharedDependency[]
{
    new SharedDependency("Core.Security.Api", input => new CoreSecurityApiCapability.CoreSecurityApiCapability().Execute(input), seed => new CoreSecurityApiCapability.CoreSecurityApiCapability().Score(seed)),
    new SharedDependency("Identity.Claims.Api", input => new IdentityClaimsApiCapability.IdentityClaimsApiCapability().Execute(input), seed => new IdentityClaimsApiCapability.IdentityClaimsApiCapability().Score(seed)),
    new SharedDependency("Identity.Tokens.Api", input => new IdentityTokensApiCapability.IdentityTokensApiCapability().Execute(input), seed => new IdentityTokensApiCapability.IdentityTokensApiCapability().Score(seed)),
    new SharedDependency("Workflow.Approval.Api", input => new WorkflowApprovalApiCapability.WorkflowApprovalApiCapability().Execute(input), seed => new WorkflowApprovalApiCapability.WorkflowApprovalApiCapability().Score(seed)),
    new SharedDependency("Workflow.Notification.Api", input => new WorkflowNotificationApiCapability.WorkflowNotificationApiCapability().Execute(input), seed => new WorkflowNotificationApiCapability.WorkflowNotificationApiCapability().Score(seed)),
    new SharedDependency("Integration.Email.Api", input => new IntegrationEmailApiCapability.IntegrationEmailApiCapability().Execute(input), seed => new IntegrationEmailApiCapability.IntegrationEmailApiCapability().Score(seed))
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
