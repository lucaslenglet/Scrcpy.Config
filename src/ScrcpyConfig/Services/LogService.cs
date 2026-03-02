namespace ScrcpyConfig.Services;

public class LogService(string logPath)
{
    public void Log(string message)
    {
        var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        File.AppendAllText(logPath, $"[{timestamp}] {message}{Environment.NewLine}");
    }
}
