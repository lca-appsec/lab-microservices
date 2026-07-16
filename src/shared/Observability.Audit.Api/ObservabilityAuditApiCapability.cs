namespace ObservabilityAuditApiCapability;

public interface ISharedCapability
{
    string Component { get; }
    string Execute(string input);
    int Score(int seed);
}

public sealed class ObservabilityAuditApiCapability : ISharedCapability
{
    public string Component => "Observability.Audit.Api";

    public string Execute(string input)
    {
        var normalized = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim().ToUpperInvariant();
        return $"{Component}: {normalized}";
    }

    public int Score(int seed)
    {
        return Math.Abs(seed * 25) % 100;
    }
}
