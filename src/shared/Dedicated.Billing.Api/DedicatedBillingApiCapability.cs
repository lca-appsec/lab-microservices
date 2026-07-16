namespace DedicatedBillingApiCapability;

public sealed class DedicatedBillingApiCapability
{
    public string Component => "Dedicated.Billing.Api";

    public string Execute(string input)
    {
        return $"{Component}: dedicated billing flow for {input}";
    }
}
