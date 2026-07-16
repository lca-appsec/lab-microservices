using Shared_Module01;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => new
{
    service = "Service01.Api",
    sharedModules = 36,
    message = "Veracode .NET microservice duplication lab"
});

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "Service01.Api" }));

app.MapGet("/work/{input}", (string input) =>
{
    var module = new ModuleService();
    return Results.Ok(new
    {
        service = "Service01.Api",
        module = module.Name,
        result = module.Execute(input),
        score = module.CalculateRiskScore(input.GetHashCode())
    });
});

app.Run();
