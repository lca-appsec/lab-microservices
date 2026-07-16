namespace ReportingExportApiCapability;

public interface ISharedCapability
{
    string Component { get; }
    string Execute(string input);
    int Score(int seed);
}

public sealed class ReportingExportApiCapability : ISharedCapability
{
    public string Component => "Reporting.Export.Api";

    public string Execute(string input)
    {
        var normalized = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim().ToUpperInvariant();
        return $"{Component}: {normalized}";
    }

    public int Score(int seed)
    {
        return Math.Abs(seed * 34) % 100;
    }
}
