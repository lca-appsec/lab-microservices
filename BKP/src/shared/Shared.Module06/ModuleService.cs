namespace Shared_Module06;

public sealed class ModuleService
{
    public string Name => "Shared.Module06";

    public string Execute(string input)
    {
        var value = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim();
        return $"{Name}: processed {value}";
    }

    public int CalculateRiskScore(int seed)
    {
        return Math.Abs(seed * 8) % 100;
    }
}
