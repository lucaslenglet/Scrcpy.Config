using System.Text.RegularExpressions;

namespace ScrcpyConfig.Forms;

public partial class IpConfigDialog : Form
{
    public string IpAddress { get; private set; } = string.Empty;

    private readonly TextBox _ipTextBox;
    private readonly Label _errorLabel;

    public IpConfigDialog(string? currentIp)
    {
        Text = "Configurer l'adresse IP";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(320, 140);
        ShowInTaskbar = false;

        var instructionLabel = new Label
        {
            Text = "Adresse IP et port du dispositif (ex : 192.168.1.1:5555) :",
            Location = new Point(12, 14),
            Size = new Size(296, 32),
            AutoSize = false,
        };

        _ipTextBox = new TextBox
        {
            Text = currentIp ?? string.Empty,
            Location = new Point(12, 50),
            Size = new Size(296, 23),
            MaxLength = 64,
        };

        _errorLabel = new Label
        {
            Text = "Format invalide. Utilisez le format : 192.168.1.1:5555",
            ForeColor = Color.Red,
            Location = new Point(12, 78),
            Size = new Size(296, 18),
            Visible = false,
            AutoSize = false,
        };

        var okButton = new Button
        {
            Text = "OK",
            DialogResult = DialogResult.None,
            Location = new Point(152, 104),
            Size = new Size(75, 26),
        };
        okButton.Click += OkButton_Click;

        var cancelButton = new Button
        {
            Text = "Annuler",
            DialogResult = DialogResult.Cancel,
            Location = new Point(233, 104),
            Size = new Size(75, 26),
        };

        AcceptButton = okButton;
        CancelButton = cancelButton;
        Controls.AddRange([instructionLabel, _ipTextBox, _errorLabel, okButton, cancelButton]);
    }

    public static bool IsValidIpAddress(string? ipAddress)
    {
        if (ipAddress is { Length: > 0})
        {
            return GetIpPortRegex().IsMatch(ipAddress);
        }
        return false;
    }

    private void OkButton_Click(object? sender, EventArgs e)
    {
        var input = _ipTextBox.Text.Trim();
        if (!IsValidIpAddress(input))
        {
            _errorLabel.Visible = true;
            _ipTextBox.Focus();
            _ipTextBox.SelectAll();
            return;
        }
        IpAddress = input;
        DialogResult = DialogResult.OK;
        Close();
    }

    [GeneratedRegex(@"^\d{1,3}(\.\d{1,3}){3}:\d+$", RegexOptions.Compiled)]
    private static partial Regex GetIpPortRegex();
}
