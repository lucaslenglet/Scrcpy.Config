using System.Text.Json;
using ScrcpyConfig.Models;

namespace ScrcpyConfig.Services;

public class ConfigService
{
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };

    public string ConfigDirectory { get; }
    public string ConfigPath { get; }
    public string LogPath { get; }
    private readonly string _readmePath;

    public ConfigService()
    {
        ConfigDirectory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "ScrcpyAudioBridge");
        ConfigPath = Path.Combine(ConfigDirectory, "scrcpy-config.json");
        LogPath = Path.Combine(ConfigDirectory, "scrcpy-tray.log");
        _readmePath = Path.Combine(ConfigDirectory, "scrcpy-config.README.md");

        EnsureFilesExist();
    }

    private void EnsureFilesExist()
    {
        Directory.CreateDirectory(ConfigDirectory);

        if (!File.Exists(ConfigPath))
        {
            var defaultConfig = new AppConfig { Mode = "usb" };
            File.WriteAllText(ConfigPath, JsonSerializer.Serialize(defaultConfig, JsonOptions));
        }

        if (!File.Exists(_readmePath))
        {
            File.WriteAllText(_readmePath, """
                # scrcpy-config.json

                - "mode" : "usb" ou "ip"
                - "ip" : (optionnel) adresse IP et port pour le mode IP, ex : "192.168.1.178:41393"

                Exemples :
                ```json
                {
                    "mode": "usb"
                }
                ```
                ```json
                {
                    "mode": "ip",
                    "ip": "192.168.1.178:41393"
                }
                ```
                """);
        }
    }

    public AppConfig GetConfig()
    {
        var json = File.ReadAllText(ConfigPath);
        return JsonSerializer.Deserialize<AppConfig>(json, JsonOptions) ?? new AppConfig();
    }

    public void SaveConfig(AppConfig config)
    {
        File.WriteAllText(ConfigPath, JsonSerializer.Serialize(config, JsonOptions));
    }
}
