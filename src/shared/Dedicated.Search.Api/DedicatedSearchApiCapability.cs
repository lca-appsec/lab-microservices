namespace DedicatedSearchApiCapability;

public sealed class DedicatedSearchApiCapability
{
    public string Component => "Dedicated.Search.Api";

    public string Execute(string input)
    {
        return $"{Component}: dedicated search index for {input}";
    }
}
