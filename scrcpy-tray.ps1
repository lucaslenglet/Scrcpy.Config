# Scrcpy Tray App - Configurable bridge with systray and config folder shortcut

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Dossier et fichiers de config
$configDir = Join-Path $env:APPDATA "ScrcpyAudioBridge"
$configPath = Join-Path $configDir "scrcpy-config.json"
$readmePath = Join-Path $configDir "scrcpy-config.README.md"

# Création du dossier et des fichiers si besoin
if (-not (Test-Path $configDir)) {
    New-Item -Path $configDir -ItemType Directory | Out-Null
}
if (-not (Test-Path $configPath)) {
    $defaultConfig = @(
        '{'
        '    "mode": "usb"'
        '}'
    )
    $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8 -Force
}
if (-not (Test-Path $readmePath)) {
    $readmeContent = @(
        '# scrcpy-config.json'
        ''
        '- "mode" : "usb" ou "ip"'
        '- "ip" : (optionnel) adresse IP et port pour le mode IP, ex : "192.168.1.178:41393"'
        ''
        'Exemples :'
        '```json'
        '{'
        '    "mode": "usb"'
        '}'
        '```'
        '```json'
        '{'
        '    "mode": "ip",'
        '    "ip": "192.168.1.178:41393"'
        '}'
        '```'
    )
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8 -Force
}

function Get-ScrcpyArgs {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        if ($config.mode -eq "ip" -and $config.ip) {
            return "--no-window -w --audio-buffer=50 --tcpip=+$($config.ip)"
        }
    } catch {
        # Si erreur de parsing, fallback USB
    }
    return "--no-window -w --audio-buffer=50"
}

$global:scrcpyProcess = $null



function Start-Bridge {
    if ($global:scrcpyProcess -and !$global:scrcpyProcess.HasExited) {
        [System.Windows.Forms.MessageBox]::Show("Le bridge est déjà actif.", "Info")
        return
    }
    $scrcpyArgs = Get-ScrcpyArgs
    $global:scrcpyProcess = Start-Process "scrcpy" -ArgumentList $scrcpyArgs -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 300
    Update-TrayStatus
}

function Stop-Bridge {
    if ($global:scrcpyProcess -and !$global:scrcpyProcess.HasExited) {
        $global:scrcpyProcess | Stop-Process -Force
        $global:scrcpyProcess = $null
    }
    Update-TrayStatus
}

function Set-Mode {
    param($mode)
    $config = @{}
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
    } catch {}
    $config.mode = $mode
    if ($mode -eq "ip" -and -not $config.ip) {
        $config.ip = "192.168.1.178:41393" # Valeur par défaut, à éditer dans le JSON
    }
    $config | ConvertTo-Json | Out-File -FilePath $configPath -Encoding UTF8 -Force
    if ($global:scrcpyProcess -and !$global:scrcpyProcess.HasExited) {
        Stop-Bridge
        Start-Bridge
    }
}

function Open-ConfigFolder {
    Start-Process explorer.exe $configDir
}

# Icône tray embarquée (Base64)
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$iconBaseOn64 = 'AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAACUWAAAlFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxl04oLZ1NjCufTc4qoE3jKqFN5S+hUfoxn1L/MZ9R/zGfUf8xn1H/MZ9R/zGfUv8xoFL/L6BR+DCfUv8wn1H/MZ9R/zGfUf8xn1H/K6BO6yygTuwvn1H8KqBN5iufTtAtn0+OMZtQKQAAAAAAAAAAAAAAAAAAAAAAAAAAKpdJaSqeTO4poU3/KaNN/yqjTf8qo07/KaNO/yqjTv8rok7/K6JO/yujTv8rok7/K6JO/yqjTv8ro07/KqJP/yqjT/8ro07/KqJO/yqjTv8qo07/KqNO/ymjTv8po03/KaNN/ymiTf8poE3vLphNawAAAAAAAAAAAAAAACyWSmspoE39KqRO/yukTv8rpE7/K6VO/yulTv8rpU//LKVP/yylT/8spE//LKRP/y2lT/8spFD/LKRQ/yylUP8spVD/LKRQ/yylUP8spU//K6VP/yulT/8rpU//K6RO/yulT/8qpU//KqVP/yqkT/8pok7+LZdMbAAAAAAtlEoqKp9N8CukUP8spU//LKZP/yylT/8spVD/K6NO/yiYSf8olkj/KJdI/yiWSP8olkj/KJZI/yiWSP8plkn/KZZJ/yiXSf8olkn/KJZJ/yiXSf8omEn/KJdJ/yiZSf8ro07/LKVQ/yymUP8rplD/K6VQ/yqlUP8roE7wLpNLKy6bT5ErpU//LKZQ/y2mUP8sp1D/LadQ/y2mUP9Fp2H/psGu/6jBr/+owbD/qMGw/6nBsP+pwbD/qcGw/6nBsP+pwbD/qcKw/6nCsP+pwbD/qcGw/6rCsP+pwrD/p8Cu/0SoYf8sp1D/LadR/y2nUf8sp1D/K6ZQ/yukUP8tnE6OL6BR2SynUf8tqFH/LaZQ/yqbS/8rmUv/K6RN/1KvbP/m5ub/6ejo/+no6P/p6Oj/6ejo/+no6P/p6Oj/6ejo/+np6P/q6On/6ejp/+np6P/p6Oj/6ujp/+rp6f/m5+X/Ua9s/yqkTv8smkz/KpxM/yynUP8sqVH/LKdR/zChUdYzpVb7LahS/y+oUv8/oFv/psKu/7rMv/9dpnL/Ua5q/+Tl5P/m5uf/5ufm/+fn5//m5+f/5ufm/+jn5//j5eT/5+fm/+fn5v/n5+b/5ebl/+fn5//n5+f/5+fn/+Tl4/9PrWr/XKRy/7nMv/+mwq7/PqFb/y2pUv8tqVL/NqdX+jOnV/8vqVP/LahQ/4/Dnv/v7O7/7Orr/8jZzf9ZsHD/5ebl/+jn6P/o5+j/6Ojo/+jo6P/q6On/wNvI/2S6fP/b4t3/6ejo/+jn5/97uYz/yd3O/+no6f/o6Oj/5eXk/1iucP/H2cz/6+rr/+7r7f+Pw57/K6hQ/y6qU/84qln/NapZ/zCrVf8uqlH/oM2s/+7r7f/p6en/0uDW/16zdf/m6Ob/6enp/+rp6f/s6uv/7Orr/7nZwv9Fs2X/Pa5e/9fi2f/d4t3/qc+z/6TJr/9yu4b/6unp/+np6f/m5+X/XbF0/9Ph1//p6en/7Ors/6DNrf8sq1H/L6xU/zqsW/83rFv/Mq1X/y+sVP+gz63/7uzt/+rq6v/T4db/X7V2/+fo5//r6ur/yN7N/33Fkv96xZH/QbRj/zSvWP9CsWL/y93P/8TZyf9msnv/vNjE/2Cydv/X49n/6urp/+bo5v9ds3X/1OHY/+rq6v/t7O3/oc6u/y2rU/8wrlX/PK5d/zmtXf8zr1n/Mq1W/6LPsP/v7e7/7Ovr/9Xh2P9ht3j/6Ono/+/s7f+jz6//MK1V/zSvWf82sFv/N7Fb/0OyZP/B1sf/arl//5nHpf+Tx6L/e8CP/77axf/t6+z/6Onn/1+1eP/V4tn/6+vr/+/s7v+i0LD/L61W/zKuV/8+sF//O69f/zWwWv8zsFj/o9Gw//Du7//t7ez/1uPZ/2K4ev/p6+n/8O7v/6XQsf81sFr/OLNd/ziyXf84sl3/Q7Rk/87g0/9lsnr/oMys/43Enf+BxZT/udjC/+/t7v/p6un/Ybd6/9bk2v/s7Oz/8O3v/6PRsP8xr1f/NLFa/z+yYf88sWH/NrJc/zSxWf+j07H/8e/w/+3t7f/X5dr/Y7p8/+rr6v/w7+//sc+5/z+aW/8/n1z/NatZ/zm0Xf9FtWX/u9XC/5a9ov+AwpP/q861/229hP/N39L/7u7t/+ns6f9juXz/1+Tb/+3u7f/x7/D/pNKy/zKxWf82tFz/QLRj/z2zY/84s17/NrJc/6XTs//y8PH/7+7u/9jl3P9lvH7/6+zr/+7t7f/r7Ov/3+Th/93j3/+BtZH/NqhY/0W1Zv/e6OH/3OTe/3euiP/H387/YrJ6/+jr6f/v7u7/6+3r/2W7fv/Z5dz/7u7u//Lw8f+m1LT/NbNc/zi1X/9BtWT/P7Nl/zm1YP84tF7/p9S1//Tx8//w8PD/2ufd/2a9gP/s7u3/7+/v/+/v7//w8PD/8PDw/+/u7v+QvJ3/RaRi/97o4f/w8PD/7O3s/3W0if+rzbb/8vHy//Dw7//t7uz/Z72A/9rn3v/v7+//8/Dy/6fWtf83tV7/Ordh/0K3Zv9AtWb/Ordi/zm2X/+m17X/9fP0//Hx8f/b6t//aMCC/+3v7f/w8fD/8PHw//Dw8P/w8fD/8fHw//Dw7//K2c//7e/t//Hx8P/w8fD/0t7W/+7v7v/x8PD/8fHw/+3v7f9pv4L/3Ong//Hx8P/08fP/qNi3/zi4YP88uWL/RLlo/0G3aP88uGP/O7hi/3nMk//t8O7/9PLz/7Dcvf9jwYD/8fHx//Ty9P/08/P/9fP0//Xy9P/08/P/9fP0//bz9f/18/T/9fP0//Xz9P/28/T/9fP0//Xy8//18vP/8fHx/2LBf/+u3Lz/8/Lz/+zw7f95zJP/O7lj/zy6ZP9Gumr/Q7hq/z26Zv8/u2b/Qbtn/2bHhP9zy4//S71v/1C7cv+GxZn/h8Oa/4fDmf+Gw5n/hsOZ/4bDmv+Gw5n/hsOZ/4bDmf+Gw5n/hcSZ/4bDmf+Fw5n/hcOY/4XDmP+Ew5j/Tbtw/0m/bv9zzI//ZciE/0C9Z/8/vGf/Prtm/0a7a/9Fu2z/QLxo/0G9af9Dvmn/Q71p/0K9af9Fvmv/Vb12/6jKsv+sy7X/rMq1/6zKtf+sy7X/rMu1/6zKtf+sy7X/rMu1/6zKtf+sy7X/rMu1/63Ltv+ty7b/rMu1/6fJsf9UvXX/Q79q/0G/af9Cvmn/Qr9q/0G/af9Avmj/SL1t/0e+bv9Cv2v/RL9r/0XAbP9GwG3/RsBt/0fBbf9Sw3T/4O7k//j29//39vf/+ff4//r3+f/39/f/+Pb3//j29//49/f/+Pf3//j29//69/n/+ff4//j29//49vf/4O/k/1HDdf9FwW3/RcJt/0XCbf9EwWz/Q8Fr/0LBa/9Kv2//Sb9w/0XBbf9HwW7/SMJv/0jCb/9Jwm//SsJw/0nCbv+j3LT/+PX3//b19f/O6Nb/suDB//Pz8//19fT/9fX0//X09f/19fT/8/Tz/7Pgwf/P6Nf/9vX1//j19/+j3LX/RsJt/0jDb/9Hw2//RsNv/0bDbv9Gw27/RcJu/0zBcf9MwXL/R8Nv/0nEcP9KxHH/SsRx/0rEcf9MxHL/TMRy/1zJfv/d7+L/+vf5/5fKp/9jtn7/7vLv//b29f/19vX/9fX1//b19f/t8e7/YrV9/5nLqf/69/n/3u/j/1vJfv9KxXH/SsZx/0nFcf9JxXH/SMZw/0fFcP9HxG//TsNz/03DdP9IxHH/SsVx/0zGcv9MxnP/TMZz/03HdP9Ox3T/TsZ0/3jTlf/p8+v/8vPy/+nu6//39/f/9vb2//b29v/29/b/9vf2//f39//p7ur/8vPx/+rz7P9305T/TMdz/03HdP9MyHT/S8h0/0rHc/9Jx3L/Scdy/0nGcf9QxHX/T8R2/0vGc/9NxnT/Tcd1/07Idf9PyHX/T8h2/1DJd/9SyXj/Uch3/3fTlf/W7N3/+/j5//n3+P/39/f/9/f3//f29//39/f/+ff4//r3+f/W7N3/dtSU/0/Jdv9Qynj/T8p3/07Jdv9OyXb/TMl1/0zJdf9LyHT/S8h0/1LGd/9Rxnj/Tch1/0/Jdf9PyXb/UMl2/1DKd/9Synj/U8p5/1TLev9VzHz/Ucd3/4jJnf+v47//0e3Z/+v07v/y9vP/8vbz/+z07v/S7tr/seTB/4rJn/9OyHb/U8x7/1PMev9RzHn/UMx4/1DLeP9Py3j/Tst3/07Kd/9Oynb/VMh5/1PIevlPynf/UMt4/1HMeP9Sy3n/Usx5/1PNev9VzXv/Vs18/1fOff9mx4b/ntqx/1bNfP9bz3//aNGK/3TVkv901ZP/aNKK/1rOf/9Wznz/ody0/2XGhf9Vz3z/VM58/1POe/9Sznr/Uc56/1HNev9QzXn/UM15/1DMeP9Vynr2Ust61VHLef9SzHr/U816/1PNe/9UzXz/Vc59/1bOfv9Xzn7/V85+/3bVlf9q04z/Wc+A/1rQgP9a0ID/WtCA/1rQgf9a0IH/WtCA/1nQgP9r1Y3/d9aW/1bPfv9W0H7/Vc99/1TPff9Tz3z/U898/1LOe/9SzXr/Uc16/1XNfNJZzoCUU8x7/1TNfP9VzXz/Vs59/1fPfv9Yz37/WM9//1nQgP9a0IH/WtCA/1vRgf9c0YL/XNGD/1zRg/9c0oP/XNGD/1zSg/9c0oP/XNGD/1rRgv9Z0YH/WdGB/1jRgP9X0YD/VtF//1XQfv9V0H3/VNB9/1TPfP9Uzn3/XdKDkmPUiCxZ0IDwVc99/1bPfv9X0H7/WdF//1rRgP9b0YH/XNKC/1zSgv9d0oP/XdKD/17Tg/9e04T/XtOE/17UhP9e1IT/XtOE/17UhP9d1IT/XdSE/1zTg/9b1IP/WtSC/1nTgf9Y04D/WNKA/1fRf/9W0X//VtF+/1zSg/Br2o8rAAAAAGfXi2pc0oL9WNF//1rSgP9b0oH/XNOC/1zTg/9e04P/XtSE/1/Uhf9g1IX/YNSF/2DVhv9h1Yb/YdWG/2HVhv9g1Yb/YNWG/1/Vhv9f1oX/XtWF/13VhP9c1YT/XNSD/1vUgv9a1IL/WdOB/1nSgf9e1IX9bNuRagAAAAAAAAAAAAAAAHDclGhk1oruXdOD/1zSgv9d0oP/XdOE/1/Uhf9g1IX/YNSG/2HVhv9h1Yb/YtWH/2LWh/9i1of/YtaH/2HVh/9h1Yb/YNWH/1/Whv9f1oX/XtWF/17Vhf9d1YT/XdWE/1zUhP9e1YX/aNmN7nXfmWkAAAAAAAAAAAAAAAAAAAAAAAAAAH/joSd03peLbduRzmvakO1t25L/btyT/2/dk/9w3JT/cNyU/3Hdlf9x3ZX/cd2V/3Helf5x3ZX/cd2V/3Helf9w3ZT/cN2V/3DdlP9w3ZT/cN2U/2/dk/xs3JDlcd2UzHngnImG6KgnAAAAAAAAAAAAAAAA4AAAB8AAAAOAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAABwAAAA+AAAAc='
$iconBaseOff64 = 'AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAACQWAAAkFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxNpcoLTKdjCswn84qLqDjKi+h5S8zofoxNZ//MTaf/zE2n/8xNp//MTaf/zE1n/8xNaD/LzOg+DAzn/8wNJ//MTaf/zE2n/8xNp//Ky+g6ywxoOwvMp/8Ki6g5isvn9AtMZ+OMTWbKQAAAAAAAAAAAAAAAAAAAAAAAAAAKi+XaSovnu4pLaH/KS6j/yovo/8qLqP/KS2j/youo/8rMKL/KzCi/yswo/8rMKL/KzCi/youo/8rMKP/Ki2i/yoto/8rMKP/Ki6i/youo/8qLqP/Ki6j/ykto/8pLqP/KS6j/yktov8pLaDvLjKYawAAAAAAAAAAAAAAACwxlmspLaD9Ki+k/yswpP8rMKT/KzGl/ysxpf8rMKX/LDGl/ywxpf8sMaT/LDGk/y0zpf8sMKT/LDCk/ywwpf8sMKX/LDCk/ywwpf8sMaX/KzCl/yswpf8rMKX/KzCk/yswpf8qLqX/Ki6l/youpP8pLKL+LTGXbAAAAAAtMpQqKi6f8CsupP8sMaX/LDKm/ywxpf8sMKX/KzCj/ygsmP8oLZb/KC2X/ygtlv8oLZb/KC2W/ygtlv8pLZb/KS2W/ygsl/8oLJb/KCyW/ygsl/8oLJj/KCyX/ygtmf8rMKP/LDCl/ywxpv8rL6b/Ky+l/yotpf8rL6DwLjOTKy4xm5ErMKX/LDGm/y0ypv8sMaf/LTOn/y0ypv9FSqf/pqfB/6ipwf+oqMH/qKjB/6mqwf+pqsH/qarB/6mqwf+pqsH/qarC/6mqwv+pqsH/qarB/6qswv+pqsL/p6jA/0RIqP8sMaf/LTKn/y0yp/8sMaf/Ky+m/ysupP8tMZyOLzOg2Swwp/8tMqj/LTKm/yovm/8rMJn/KzGk/1JXr//m5ub/6Ono/+jp6P/o6ej/6Ono/+jp6P/o6ej/6Ono/+jp6f/q6uj/6eno/+jp6f/o6ej/6uro/+nq6f/l5+f/UVWv/yovpP8sMZr/Ki6c/ywxp/8sMan/LDCn/zA1odYzNqX7LTGo/y80qP8/Q6D/pqfC/7q7zP9dYKb/UVeu/+Tk5f/n5ub/5ubn/+fn5//n5uf/5ubn/+fo5//j4+X/5ufn/+bn5//m5+f/5eXm/+fn5//n5+f/5+fn/+Pl5f9PU63/XF6k/7m5zP+mp8L/PkKh/y0xqf8tMan/Njun+jM2p/8vNKn/LTOo/4+Rw//v7+z/7Ozq/8jJ2f9ZX7D/5eXm/+jo5//o6Of/6Ojo/+jo6P/q6uj/wMHb/2Rpuv/b2+L/6Ono/+fo5/97f7n/ycvd/+np6P/o6Oj/5OXl/1hdrv/HyNn/6+vq/+7u6/+PkcP/KzCo/y4yqv84Par/NTiq/zA0q/8uNKr/oKPN/+7u6//p6en/0tPg/15js//m5+j/6enp/+nq6f/s7Or/7Ozq/7m72f9FSrP/PUKu/9fZ4v/d3+L/qazP/6Slyf9ydrv/6erp/+np6f/l5+f/XWKx/9PU4f/p6en/7Ovq/6Cizf8sMav/LzSs/zo/rP83Oqz/Mjat/y80rP+go8//7u7s/+rq6v/T1eH/X2W1/+fn6P/q6+r/yMre/32Axf96fMX/QUW0/zQ5r/9CR7H/y83d/8TG2f9marL/vL3Y/2Blsv/X2eP/6erq/+bn6P9dYrP/1NTh/+rq6v/t7ez/oaPO/y0xq/8wNa7/PEGu/zk8rf8zNq//Mjet/6Kjz//v7+3/6+zr/9XW4f9hZ7f/6Ojp/+7v7P+jps//MDWt/zQ4r/82OrD/Nzyx/0NHsv/Bwtb/am+5/5mcx/+Tlcf/e37A/77A2v/t7ev/5+np/19jtf/V1eL/6+vr/+/v7P+io9D/LzKt/zI2rv8+Q7D/Oz6v/zU5sP8zOLD/o6XR//Dw7v/s7e3/1tfj/2JnuP/p6uv/8PDu/6Wn0P81ObD/ODyz/zg8sv84PLL/Q0i0/87P4P9larL/oKPM/42PxP+BhcX/ubrY/+/v7f/p6er/YWW3/9bX5P/s7Oz/8PDt/6Ol0f8xNa//NDix/z9Dsv88PrH/Njmy/zQ5sf+jpdP/8fHv/+3t7f/X2eX/Y2e6/+rq6//v8O//sbPP/z9Bmv8/Qp//NTir/zk+tP9FSrX/u73V/5aXvf+Ag8L/q63O/21xvf/Nzt//7e7u/+nq7P9jZ7n/19fk/+3t7v/x8e//pKXS/zI1sf82OrT/QES0/z0+s/84O7P/Njmy/6Wm0//y8vD/7u/u/9jY5f9labz/6+vs/+3u7f/r6+z/39/k/93d4/+BgrX/Njqo/0VJtf/e3uj/3N3k/3d4rv/HyN//YmWy/+jo6//u7+7/6+zt/2Vpu//Z2uX/7u7u//Ly8P+mp9T/NTiz/zg7tf9BRbX/P0Cz/zk7tf84O7T/p6jU//T08f/w8PD/2tvn/2Zpvf/s7O7/7+/v/+/v7//w8PD/8PDw/+7v7v+Qkrz/RUik/97e6P/w8PD/7Ozt/3V2tP+rq83/8vLx/+/w8P/s7u7/Z2u9/9ra5//v7+//8/Pw/6ep1v83OrX/Oj23/0JFt/9AQbX/Ojy3/zk9tv+mp9f/9fXz//Hx8f/b3Or/aGvA/+3u7//w8PH/8PDx//Dw8P/w8PH/8PHx/+/w8P/Kytn/7e7v//Dx8f/w8PH/0tLe/+7u7//w8fD/8PHx/+3u7/9pbb//3Nzp//Dx8f/09PH/qKnY/zg7uP88QLn/REe5/0FBt/88Prj/Oz64/3l7zP/t7fD/9PTy/7Cy3P9jZcH/8fHx//Tz8v/z9PP/9fXz//X18v/z9PP/9fXz//b28//19fP/9fXz//X18//19vP/9fXz//T18v/09fL/8fHx/2Jlwf+ur9z/8/Py/+zs8P95e8z/Oz25/zw+uv9GSbr/Q0O4/z0+uv8/Qbv/QUS7/2Zox/9zdMv/S029/1BSu/+GiMX/h4jD/4eJw/+Gh8P/hofD/4aGw/+Gh8P/hofD/4aHw/+Gh8P/hYbE/4aHw/+FhsP/hYfD/4WHw/+EhcP/TU+7/0lLv/9zdcz/ZWfI/0BDvf8/Qbz/PkC7/0ZIu/9FRbv/QEG8/0FCvf9DRr7/Q0a9/0JEvf9FR77/VVe9/6ipyv+srcv/rK3K/6ytyv+srcv/rK3L/6ytyv+srcv/rK3L/6ytyv+srcv/rK3L/62uy/+trsv/rK3L/6eoyf9UVr3/Q0W//0FDv/9CRL7/QkS//0FDv/9AQr7/SEq9/0dIvv9CQ7//REa//0VHwP9GSMD/RkjA/0dKwf9SVsP/4OHu//j49v/39/b/+fn3//r69//39/f/+Pj2//j49v/3+Pf/9/j3//j49v/6+vf/+fn3//j49v/4+Pb/4OHv/1FTw/9FRsH/RUfC/0VHwv9ERsH/Q0XB/0JDwf9KTL//SUm//0VGwf9HScH/SErC/0hKwv9JS8L/SkzC/0lMwv+jpdz/+Pj1//X29f/Oz+j/srLg//Pz8//09fX/9PX1//X19P/09fX/8/P0/7O04P/Pz+j/9fb1//j49f+jpNz/RkjC/0hKw/9HSMP/RkfD/0ZIw/9GSMP/RUbC/0xOwf9MTcH/R0jD/0lLxP9KTMT/SkzE/0pMxP9MTsT/TE7E/1xeyf/d3u//+vr3/5eYyv9jZLb/7u7y//X29v/19fb/9fX1//X29f/t7fH/YmO1/5may//6+vf/3t/v/1tdyf9KTMX/SkzG/0lKxf9JSsX/SErG/0dIxf9HScT/TlDD/01Nw/9ISMT/SkzF/0xPxv9MTsb/TE7G/01Px/9OUMf/TlDG/3h50//p6vP/8vLz/+np7v/39/f/9vb2//b29v/29vf/9vb3//f39//p6u7/8fPz/+rr8/93edP/TE7H/01Px/9MTcj/S0zI/0pLx/9JSsf/SUrH/0lLxv9QUsT/T0/E/0tMxv9NTsb/TU7H/05QyP9PUcj/T1DI/1BRyf9SVMn/UVPI/3d40//W1uz/+vv4//n59//39/f/9/f3//f39v/39/f/+fn3//r69//W1uz/dnfU/09Ryf9QUcr/T1DK/05Pyf9OT8n/TE3J/0xNyf9LTMj/S0zI/1JUxv9RUcb/TU7I/09Syf9PUcn/UFLJ/1BSyv9SVMr/U1XK/1RWy/9VVsz/UVLH/4iJyf+vsOP/0dLt/+vr9P/y8vb/8vL2/+zt9P/S0+7/sbLk/4qKyf9OT8j/U1PM/1NUzP9RUsz/UFHM/1BRy/9PT8v/Tk/L/05Oyv9OT8r/VFbI/1NTyPlPUMr/UFHL/1FTzP9SU8v/UlTM/1NVzf9VV83/VljN/1dZzv9mZsf/np/a/1ZYzf9bXs//aGnR/3R21f90ddX/aGnS/1pczv9WWM7/oaLc/2Vlxv9VV8//VFXO/1NUzv9SU87/UVLO/1FRzf9QUc3/UFHN/1BRzP9VV8r2UlLL1VFSy/9SU8z/U1XN/1NUzf9UVM3/VVXO/1ZWzv9XWM7/V1jO/3Z31f9qa9P/WVnP/1pb0P9aW9D/WlvQ/1pa0P9aWtD/WlvQ/1la0P9rbNX/d3jW/1ZWz/9WV9D/VVbP/1RUz/9TU8//U1PP/1JSzv9SU83/UVHN/1VWzdJZWc6UU1PM/1RUzf9VVs3/VlfO/1dYz/9YWs//WFnP/1la0P9aWtD/WlvQ/1tc0f9cXdH/XFzR/1xc0f9cXNL/XFzR/1xc0v9cXNL/XFzR/1pa0f9ZWdH/WVnR/1hY0f9XV9H/VlbR/1VV0P9VVtD/VFTQ/1RVz/9UVM7/XV7SkmNk1CxZWtDwVVbP/1ZWz/9XWND/WVvR/1pc0f9bXNH/XF3S/1xd0v9dXtL/XV7S/15g0/9eX9P/Xl/T/15f1P9eX9T/Xl/T/15f1P9dXtT/XV7U/1xd0/9bW9T/WlvU/1la0/9YWdP/WFnS/1dY0f9WVtH/VlfR/1xc0vBrbNorAAAAAGdo12pcXdL9WFnR/1pc0v9bXdL/XF7T/1xd0/9eYNP/Xl/U/19g1P9gYtT/YGLU/2Bh1f9hY9X/YWPV/2Fj1f9gYdX/YGHV/19f1f9fYdb/Xl/V/11e1f9cXNX/XF3U/1tc1P9aW9T/WVrT/1lZ0v9eXtT9bGzbagAAAAAAAAAAAAAAAHBw3GhkZNbuXV7T/1xd0v9dXtL/XV3T/19g1P9gYtT/YGHU/2Fj1f9hY9X/YmPV/2Jk1v9iZNb/YmTW/2Fi1f9hY9X/YGDV/19g1v9fYdb/Xl/V/15f1f9dXtX/XV7V/1xc1P9eX9X/aGnZ7nZ132kAAAAAAAAAAAAAAAAAAAAAAAAAAIB/4yd0dN6LbW7bzmtr2u1tbdv/bm7c/29w3f9wcNz/cHDc/3Fx3f9xcd3/cXHd/3Fx3v5xcd3/cXHd/3Fx3v9wcN3/cXDd/3Bw3f9wcN3/cHDd/29w3fxsbdzlcXLdzHp54ImHhugnAAAAAAAAAAAAAAAA4AAAB8AAAAOAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAABwAAAA+AAAAc='

function Update-TrayStatus {
    $icon = $iconBaseOff64
    $text = "Scrcpy Audio Bride (arrêté)"
    if ($global:scrcpyProcess -and !$global:scrcpyProcess.HasExited) {
        $icon = $iconBaseOn64
        $text = "Scrcpy Audio Bride (démarré)"
    }
    
    $notifyIcon.Text = $text

    try {
        $iconBytes = [Convert]::FromBase64String($icon)
        $iconStream = New-Object IO.MemoryStream(,$iconBytes)
        $notifyIcon.Icon = New-Object System.Drawing.Icon($iconStream)
    } catch {
        $notifyIcon.Icon = [System.Drawing.SystemIcons]::Application
    }
}

Update-TrayStatus
$notifyIcon.Visible = $true


# Menu contextuel
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$startItem = $contextMenu.Items.Add("Démarrer le bridge")
$startItem.Add_Click({ Start-Bridge })

$stopItem = $contextMenu.Items.Add("Arrêter le bridge")
$stopItem.Add_Click({ Stop-Bridge })

$contextMenu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new()) | Out-Null

$usbItem = $contextMenu.Items.Add("Mode USB")
$usbItem.Add_Click({ Set-Mode "usb" })

$ipItem = $contextMenu.Items.Add("Mode IP")
$ipItem.Add_Click({ Set-Mode "ip" })

$contextMenu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new()) | Out-Null

$configItem = $contextMenu.Items.Add("Ouvrir le dossier de config")
$configItem.Add_Click({ Open-ConfigFolder })

$contextMenu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new()) | Out-Null

$quitItem = $contextMenu.Items.Add("Quitter")
$quitItem.Add_Click({
    Stop-Bridge
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notifyIcon.ContextMenuStrip = $contextMenu

[System.Windows.Forms.Application]::Run()
