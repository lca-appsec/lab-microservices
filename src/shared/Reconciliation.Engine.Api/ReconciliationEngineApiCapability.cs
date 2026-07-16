namespace ReconciliationEngineApiCapability;

public interface ISharedCapability
{
    string Component { get; }
    string Execute(string input);
    int Score(int seed);
}

public sealed class ReconciliationEngineApiCapability : ISharedCapability
{
    public string Component => "Reconciliation.Engine.Api";

    public string Execute(string input)
    {
        var normalized = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim().ToUpperInvariant();
        return $"{Component}: {normalized}";
    }

    public int Score(int seed)
    {
        return Math.Abs(seed * 32) % 100;
    }
}
