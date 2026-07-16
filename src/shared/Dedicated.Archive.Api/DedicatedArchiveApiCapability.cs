namespace DedicatedArchiveApiCapability;

public sealed class DedicatedArchiveApiCapability
{
    public string Component => "Dedicated.Archive.Api";

    public string Execute(string input)
    {
        return $"{Component}: dedicated archive job for {input}";
    }
}
