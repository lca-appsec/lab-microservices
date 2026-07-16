namespace DedicatedRiskApiCapability;

public sealed class DedicatedRiskApiCapability
{
    public string Component => "Dedicated.Risk.Api";

    public string Execute(string input)
    {
        return $"{Component}: dedicated risk calculation for {input}";
    }
}
