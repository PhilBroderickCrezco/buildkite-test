namespace MicroserviceA.Tests;

public class TestSuite
{
    private static readonly Random Random = new();

    [Fact]
    public void AlwaysPasses()
    {
        Assert.True(true);
    }

    [Fact]
    public void FlakyTest()
    {
        // Fail randomly ~50% of the time
        var chance = Random.NextDouble();
        Assert.True(chance > 0.5, $"Flaky failure triggered! Random value: {chance}");
    }

    [Fact]
    public void AlwaysFails()
    {
        Assert.Fail("This test always fails");
    }
}