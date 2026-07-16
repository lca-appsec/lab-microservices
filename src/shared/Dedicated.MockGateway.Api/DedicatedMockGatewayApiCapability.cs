namespace DedicatedMockGatewayApiCapability;

public sealed class DedicatedMockGatewayApiCapability
{
    public string Component => "Dedicated.MockGateway.Api";

    public string Execute(string input)
    {
        return $"{Component}: dedicated mock gateway for {input}";
    }
}
