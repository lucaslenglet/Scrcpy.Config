#:sdk Cake.Sdk@6.1.0
#:package Cake.GitVersioning@3.9.50
#:package Cake.GitHub@1.0.0

var target = Argument("target", "Build");
var configuration = Argument("configuration", "Release");
var staging = Argument("staging", "./stg");

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("SetBuildVersion")
    .WithCriteria(!BuildSystem.IsLocalBuild && target == "Publish")
    .Does(() =>
    {
        GitVersioningCloud("./src/ScrcpyConfig/ScrcpyConfig.csproj", new GitVersioningCloudSettings
        {
            CloudBuildNumber = true,
        });
    });

Task("Restore")
    .Does(() =>
    {
        DotNetRestore("./ScrcpyConfig.slnx");
    });

Task("Build")
    .IsDependentOn("Restore")
    .Does(() =>
    {
        DotNetBuild("./ScrcpyConfig.slnx", new DotNetBuildSettings
        {
            Configuration = configuration,
        });
    });

Task("Publish")
    .IsDependentOn("SetBuildVersion")
    .IsDependentOn("Build")
    .Does(async () =>
    {
        DotNetPublish("./src/ScrcpyConfig/ScrcpyConfig.csproj", new DotNetPublishSettings
        {
            NoRestore = true,
            NoBuild = true,
            Configuration = configuration,
            OutputDirectory = staging,
        });

        var version = GitVersioningGetVersion(".").SemVer2;
        var tag = $"v{version}";
        var exe = $"{staging}/ScrcpyConfig.exe";
        var token = EnvironmentVariable("GITHUB_TOKEN");

        await GitHubCreateReleaseAsync(
            userName: null,
            apiToken: token,
            owner: "lucaslenglet",
            repository: "Scrcpy.Config",
            tagName: tag,
            settings: new GitHubCreateReleaseSettings { Name = tag }
        );

        StartProcess("gh", new ProcessSettings
        {
            Arguments = $"release upload {tag} {exe}",
            EnvironmentVariables = new Dictionary<string, string>
            {
                { "GH_TOKEN", token }
            }
        });
    });

//////////////////////////////////////////////////////////////////////
// EXECUTION
//////////////////////////////////////////////////////////////////////

RunTarget(target);
