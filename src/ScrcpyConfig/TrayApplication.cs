using System.Reflection;
using ScrcpyConfig.Forms;
using ScrcpyConfig.Services;

namespace ScrcpyConfig;

public class TrayApplication : ApplicationContext
{
    private readonly ConfigService _config;
    private readonly ScrcpyService _scrcpy;
    private readonly LogService _log;

    private readonly NotifyIcon _notifyIcon;
    private readonly ToolStripStatusLabel _statusLabel;

    public TrayApplication()
    {
        _log = new LogService(GetLogPath());
        _config = new ConfigService();
        _scrcpy = new ScrcpyService(_log, UpdateTrayStatus);

        _log.Log("Lancement de l'application...");
        _scrcpy.DetectRunning();

        _statusLabel = new ToolStripStatusLabel();

        var contextMenu = new ContextMenuStrip();
        contextMenu.Items.Add(_statusLabel);
        contextMenu.Items.Add(new ToolStripSeparator());

        var startItem = new ToolStripMenuItem("Démarrer le bridge");
        startItem.Click += (_, _) => StartBridge();
        contextMenu.Items.Add(startItem);

        var stopItem = new ToolStripMenuItem("Arrêter le bridge");
        stopItem.Click += (_, _) => StopBridge();
        contextMenu.Items.Add(stopItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        var usbItem = new ToolStripMenuItem("Mode USB");
        usbItem.Click += (_, _) => SetMode("usb");
        contextMenu.Items.Add(usbItem);

        var ipItem = new ToolStripMenuItem("Mode IP");
        ipItem.Click += (_, _) => SetMode("ip");
        contextMenu.Items.Add(ipItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        var configureIpItem = new ToolStripMenuItem("Configurer l'adresse IP...");
        configureIpItem.Click += (_, _) => ConfigureIpAddress();
        contextMenu.Items.Add(configureIpItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        var configItem = new ToolStripMenuItem("Ouvrir le dossier de config");
        configItem.Click += (_, _) => OpenConfigFolder();
        contextMenu.Items.Add(configItem);

        var logItem = new ToolStripMenuItem("Ouvrir le fichier de log");
        logItem.Click += (_, _) => OpenLogFile();
        contextMenu.Items.Add(logItem);

        contextMenu.Items.Add(new ToolStripSeparator());

        var quitItem = new ToolStripMenuItem("Quitter");
        quitItem.Click += (_, _) => Quit();
        contextMenu.Items.Add(quitItem);

        _notifyIcon = new NotifyIcon
        {
            ContextMenuStrip = contextMenu,
            Visible = true,
        };

        UpdateTrayStatus();
        _log.Log("Application démarrée.");
    }

    private void StartBridge()
    {
        var cfg = _config.GetConfig();
        if (!_scrcpy.Start(cfg.Mode, cfg.Ip))
        {
            MessageBox.Show("Le bridge est déjà actif.", "Info");
            return;
        }
        UpdateTrayStatus();
    }

    private void StopBridge(bool quiting = false)
    {
        if (!_scrcpy.Stop() && !quiting)
        {
            MessageBox.Show("Le bridge n'est pas actif.", "Info");
        }
    }

    private void SetMode(string mode)
    {
        if (mode == "ip")
        {
            var cfg = _config.GetConfig();
            if (!IpConfigDialog.IsValidIpAddress(cfg.Ip))
            {
                using var dialog = new IpConfigDialog(cfg.Ip);
                if (dialog.ShowDialog() != DialogResult.OK)
                    return;

                cfg.Ip = dialog.IpAddress;
            }
            cfg.Mode = "ip";
            _config.SaveConfig(cfg);
            _log.Log($"Mode changé vers: ip, adresse: {cfg.Ip}");
        }
        else
        {
            var cfg = _config.GetConfig();
            cfg.Mode = mode;
            _config.SaveConfig(cfg);
            _log.Log($"Mode changé vers: {mode}");
        }

        if (_scrcpy.IsRunning)
        {
            StopBridge();
            StartBridge();
        }

        UpdateTrayStatus();
    }

    private void ConfigureIpAddress()
    {
        var cfg = _config.GetConfig();
        using var dialog = new IpConfigDialog(cfg.Ip);
        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        cfg.Ip = dialog.IpAddress;
        _config.SaveConfig(cfg);
        _log.Log($"Adresse IP configurée: {cfg.Ip}");

        if (cfg.Mode == "ip" && _scrcpy.IsRunning)
        {
            StopBridge();
            StartBridge();
        }
    }

    private void OpenConfigFolder() =>
        System.Diagnostics.Process.Start("explorer.exe", _config.ConfigDirectory);

    private void OpenLogFile()
    {
        if (File.Exists(_config.LogPath))
            System.Diagnostics.Process.Start("notepad.exe", _config.LogPath);
        else
            MessageBox.Show("Aucun fichier de log n'existe encore.", "Info");
    }

    private void Quit()
    {
        _log.Log("Fermeture de l'application demandée.");
        StopBridge(quiting: true);
        _notifyIcon.Dispose();
        Application.Exit();
    }

    private void UpdateTrayStatus()
    {
        var running = _scrcpy.IsRunning;
        var cfg = _config.GetConfig();

        var status = running ? "Activé" : "Désactivé";
        _statusLabel.Text = $"{status} : {cfg.Mode}";
        _notifyIcon.Text = $"Scrcpy Audio Bridge ({_statusLabel.Text})";

        var iconResourceName = running
            ? "ScrcpyConfig.Resources.icon_on32.ico"
            : "ScrcpyConfig.Resources.icon_off32.ico";

        try
        {
            var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(iconResourceName);
            if (stream is not null)
                _notifyIcon.Icon = new Icon(stream);
            else
                _notifyIcon.Icon = SystemIcons.Application;
        }
        catch
        {
            _notifyIcon.Icon = SystemIcons.Application;
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
            _notifyIcon.Dispose();
        base.Dispose(disposing);
    }

    private static string GetLogPath()
    {
        var dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "ScrcpyAudioBridge");
        Directory.CreateDirectory(dir);
        return Path.Combine(dir, "scrcpy-tray.log");
    }
}
