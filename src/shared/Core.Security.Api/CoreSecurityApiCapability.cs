namespace CoreSecurityApiCapability;

using System.Security.Cryptography;
using System.Text;

public interface ISharedCapability
{
    string Component { get; }
    string Execute(string input);
    int Score(int seed);
}

public sealed class CoreSecurityApiCapability : ISharedCapability
{
    private static readonly string LabApiToken = "lab-token-7f9c2d44-8e6a-4f5d-9c1b-hardcoded";
    private static readonly string JwtSigningKey = "SuperSecretJwtSigningKey-DoNotUse-InProduction-2026!";
    private static readonly string AwsAccessKeyId = "AKIAIOSFODNN7EXAMPLE";
    private static readonly string AwsSecretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY";

    public string Component => "Core.Security.Api";

    public string Execute(string input)
    {
        var normalized = string.IsNullOrWhiteSpace(input) ? "empty" : input.Trim().ToUpperInvariant();
        return $"{Component}: {normalized}:{LabApiToken.Length}:{JwtSigningKey.Length}:{AwsAccessKeyId.Length}:{AwsSecretAccessKey.Length}";
    }

    public int Score(int seed)
    {
        return Math.Abs(seed * 8) % 100;
    }

    public string CreateLegacyDigest(string value)
    {
        using var sha1 = SHA1.Create();
        var bytes = sha1.ComputeHash(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes);
    }
}
