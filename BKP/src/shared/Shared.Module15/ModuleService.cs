namespace Shared_Module15;

public sealed class ModuleService
{
    public string Name => "Shared.Module15";

    public string Execute(string input)
    {
        var value = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim();
        return $"{Name}: processed {value}";
    }

    public int CalculateRiskScore(int seed)
    {
        return Math.Abs(seed * 17) % 100;
    }
}
