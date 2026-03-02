using System.Diagnostics;

namespace ScrcpyConfig.Services;

public class ScrcpyService(LogService log, Action updateStatus)
{
    private Process? _process;

    public bool IsRunning => _process is { HasExited: false } ||
        Process.GetProcessesByName("scrcpy").Length > 0;

    public void DetectRunning()
    {
        var running = Process.GetProcessesByName("scrcpy");
        if (running.Length > 0)
        {
            _process = running[0];
            log.Log("Processus scrcpy existant détecté au démarrage");
        }
    }

    public bool Start(string mode, string? ip)
    {
        if (_process is { HasExited: false })
        {
            return false;
        }

        var args = BuildArgs(mode, ip);
        _process = Process.Start(new ProcessStartInfo("scrcpy")
        {
            Arguments = args,
            UseShellExecute = false,
            CreateNoWindow = true,
        });

        _ = StartProcess();

        log.Log($"Bridge démarré avec les arguments: {args}");
        return true;
    }

    public bool Stop()
    {
        if (_process is null)
        {
            return false;
        }

        _process.Kill(entireProcessTree: true);
        _process = null;
        updateStatus();
        return true;
    }

    private async Task StartProcess()
    {
        await _process!.WaitForExitAsync();
        updateStatus();
        log.Log($"Bridge fermé.");
    }

    private static string BuildArgs(string mode, string? ip)
    {
        if (mode == "ip" && !string.IsNullOrWhiteSpace(ip))
            return $"--no-window -w --audio-buffer=50 --tcpip=+{ip}";

        return "--no-window -w --audio-buffer=50 --select-usb";
    }
}
