param(
    [Parameter(Mandatory = $false)]
    [string]$PackagePath = "C:\projects\SC-D70_Win11-Reproduction",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\evidence",

    [Parameter(Mandatory = $false)]
    [string]$CertificateThumbprint = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$buildOut     = Join-Path $OutputDir "sc-d70-build-package-$timestamp.txt"
$installedOut = Join-Path $OutputDir "sc-d70-installed-state-$timestamp.txt"

function Write-Section {
    param(
        [System.IO.StreamWriter]$Writer,
        [string]$Title
    )
    $Writer.WriteLine("")
    $Writer.WriteLine("=" * 88)
    $Writer.WriteLine($Title)
    $Writer.WriteLine("=" * 88)
}

function Write-CommandOutput {
    param(
        [System.IO.StreamWriter]$Writer,
        [scriptblock]$Script
    )
    try {
        $result = & $Script 2>&1 | Out-String -Width 300
        $Writer.WriteLine($result.TrimEnd())
    }
    catch {
        $Writer.WriteLine("ERROR: $($_.Exception.Message)")
    }
}

function Get-DefaultRegistryValue {
    param([string]$Path)
    try {
        return (Get-ItemProperty -LiteralPath $Path -ErrorAction Stop).'(default)'
    }
    catch {
        return $null
    }
}

# -----------------------------------------------------------------------------
# BUILD / PACKAGE EVIDENCE
# -----------------------------------------------------------------------------

$w = [System.IO.StreamWriter]::new($buildOut, $false, [System.Text.Encoding]::UTF8)
try {
    $w.WriteLine("SC-D70 Windows 11 - Build Package Evidence")
    $w.WriteLine("Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
    $w.WriteLine("PackagePath: $PackagePath")

    Write-Section $w "SYSTEM"
    Write-CommandOutput $w {
        Get-ComputerInfo |
            Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, OsArchitecture
    }

    Write-Section $w "PACKAGE FILE LIST"
    Write-CommandOutput $w {
        Get-ChildItem -LiteralPath $PackagePath -File |
            Sort-Object Name |
            Select-Object Name, Length, LastWriteTime
    }

    Write-Section $w "CORE FILE HASHES (SHA256)"
    $coreFiles = @(
        "RDIF1012.INF",
        "RDWM1012.SYS",
        "RDID1012.CAT",
        "Rdas1012.dll",
        "Rdaw1012.dll",
        "Rdah1012.dat"
    )
    foreach ($name in $coreFiles) {
        $p = Join-Path $PackagePath $name
        if (Test-Path -LiteralPath $p) {
            Write-CommandOutput $w { Get-FileHash -LiteralPath $p -Algorithm SHA256 }
        } else {
            $w.WriteLine("MISSING: $p")
        }
    }

    Write-Section $w "AUTHENTICODE - RDWM1012.SYS"
    $sys = Join-Path $PackagePath "RDWM1012.SYS"
    if (Test-Path -LiteralPath $sys) {
        Write-CommandOutput $w {
            $sig = Get-AuthenticodeSignature -LiteralPath $sys
            [PSCustomObject]@{
                Status     = $sig.Status
                StatusMessage = $sig.StatusMessage
                Subject    = $sig.SignerCertificate.Subject
                Thumbprint = $sig.SignerCertificate.Thumbprint
                NotBefore  = $sig.SignerCertificate.NotBefore
                NotAfter   = $sig.SignerCertificate.NotAfter
            }
        }
    }

    Write-Section $w "AUTHENTICODE - RDID1012.CAT"
    $cat = Join-Path $PackagePath "RDID1012.CAT"
    if (Test-Path -LiteralPath $cat) {
        Write-CommandOutput $w {
            $sig = Get-AuthenticodeSignature -LiteralPath $cat
            [PSCustomObject]@{
                Status     = $sig.Status
                StatusMessage = $sig.StatusMessage
                Subject    = $sig.SignerCertificate.Subject
                Thumbprint = $sig.SignerCertificate.Thumbprint
                NotBefore  = $sig.SignerCertificate.NotBefore
                NotAfter   = $sig.SignerCertificate.NotAfter
            }
        }
    }

    Write-Section $w "INF KEY LINES"
    $inf = Join-Path $PackagePath "RDIF1012.INF"
    if (Test-Path -LiteralPath $inf) {
        Write-CommandOutput $w {
            Select-String -LiteralPath $inf -Pattern @(
                'CatalogFile',
                'DriverVer',
                'VID_0582&PID_000C',
                'RDID1012',
                'Rdas1012.dll',
                'Rdaw1012.dll',
                'Rdah1012.dat'
            )
        }
    }

    if ($CertificateThumbprint) {
        Write-Section $w "CERTIFICATE STORES"
        $thumb = $CertificateThumbprint.Replace(" ", "")
        foreach ($store in @(
            "Cert:\LocalMachine\My\$thumb",
            "Cert:\LocalMachine\Root\$thumb",
            "Cert:\LocalMachine\TrustedPublisher\$thumb"
        )) {
            if (Test-Path -LiteralPath $store) {
                Write-CommandOutput $w {
                    Get-Item -LiteralPath $store |
                        Select-Object Subject, Thumbprint, HasPrivateKey, NotBefore, NotAfter
                }
            } else {
                $w.WriteLine("NOT PRESENT: $store")
            }
        }
    }

    Write-Section $w "END"
    $w.WriteLine("Build/package evidence capture complete.")
}
finally {
    $w.Dispose()
}

# -----------------------------------------------------------------------------
# INSTALLED STATE EVIDENCE
# -----------------------------------------------------------------------------

$w = [System.IO.StreamWriter]::new($installedOut, $false, [System.Text.Encoding]::UTF8)
try {
    $w.WriteLine("SC-D70 Windows 11 - Installed State Evidence")
    $w.WriteLine("Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")

    Write-Section $w "BOOT CONFIGURATION"
    Write-CommandOutput $w { bcdedit /enum }

    Write-Section $w "DRIVER STORE - RDIF1012 / ROLAND / SC-D70"
    Write-CommandOutput $w {
        pnputil /enum-drivers |
            Select-String -Pattern "rdif1012|Roland|SC-D70|RDID1012" -Context 4,8
    }

    Write-Section $w "CONNECTED PHYSICAL DEVICE"
    Write-CommandOutput $w {
        pnputil /enum-devices /connected /deviceids |
            Select-String -Pattern "VID_0582&PID_000C" -Context 8,12
    }

    Write-Section $w "PNP DEVICE / ENDPOINT SUMMARY"
    Write-CommandOutput $w {
        Get-PnpDevice |
            Where-Object {
                $_.FriendlyName -like "*SC-D70*" -or
                $_.InstanceId -like "*VID_0582&PID_000C*"
            } |
            Sort-Object Class, FriendlyName |
            Select-Object Status, Class, FriendlyName, InstanceId
    }

    Write-Section $w "INSTALLED FILE PRESENCE"
    $installedFiles = @(
        "C:\Windows\System32\drivers\RDWM1012.SYS",
        "C:\Windows\System32\Rdas1012.dll",
        "C:\Windows\SysWOW64\Rdaw1012.dll",
        "C:\Windows\SysWOW64\Rdah1012.dat"
    )
    foreach ($p in $installedFiles) {
        $w.WriteLine("$p`t$(Test-Path -LiteralPath $p)")
    }

    Write-Section $w "INSTALLED FILE HASHES (SHA256)"
    foreach ($p in $installedFiles) {
        if (Test-Path -LiteralPath $p) {
            Write-CommandOutput $w { Get-FileHash -LiteralPath $p -Algorithm SHA256 }
        }
    }

    Write-Section $w "INSTALLED KERNEL DRIVER AUTHENTICODE"
    $installedSys = "C:\Windows\System32\drivers\RDWM1012.SYS"
    if (Test-Path -LiteralPath $installedSys) {
        Write-CommandOutput $w {
            $sig = Get-AuthenticodeSignature -LiteralPath $installedSys
            [PSCustomObject]@{
                Status     = $sig.Status
                StatusMessage = $sig.StatusMessage
                Subject    = $sig.SignerCertificate.Subject
                Thumbprint = $sig.SignerCertificate.Thumbprint
            }
        }
    }

    Write-Section $w "ASIO / COM REGISTRY"
    $clsid = "{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}"
    $regPaths = @(
        "HKLM:\SOFTWARE\ASIO\Roland SC-D70",
        "HKLM:\SOFTWARE\WOW6432Node\ASIO\Roland SC-D70",
        "HKLM:\SOFTWARE\Classes\CLSID\$clsid",
        "HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\$clsid"
    )
    foreach ($p in $regPaths) {
        $w.WriteLine("$p`t$(Test-Path -LiteralPath $p)")
    }

    Write-Section $w "ASIO COM MAPPING"
    $asio64 = "HKLM:\SOFTWARE\Classes\CLSID\$clsid\InprocServer32"
    $asio32 = "HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\$clsid\InprocServer32"
    [PSCustomObject]@{
        ASIO64 = Get-DefaultRegistryValue $asio64
        ASIO32 = Get-DefaultRegistryValue $asio32
    } | Out-String -Width 300 | ForEach-Object { $w.WriteLine($_.TrimEnd()) }

    if ($CertificateThumbprint) {
        Write-Section $w "CERTIFICATE TRUST"
        $thumb = $CertificateThumbprint.Replace(" ", "")
        foreach ($store in @(
            "Cert:\LocalMachine\Root\$thumb",
            "Cert:\LocalMachine\TrustedPublisher\$thumb"
        )) {
            $w.WriteLine("$store`t$(Test-Path -LiteralPath $store)")
        }
    }

    Write-Section $w "MANUAL FUNCTIONAL TESTS"
    $w.WriteLine("These are intentionally not inferred by the script.")
    $w.WriteLine("Record them in the reproduction log:")
    $w.WriteLine("  Windows USB Audio actual playback : PASS / FAIL")
    $w.WriteLine("  MIDI PART A actual playback       : PASS / FAIL")
    $w.WriteLine("  MIDI PART B actual playback       : PASS / FAIL")
    $w.WriteLine("  ASIO host loading                 : PASS / FAIL")
    $w.WriteLine("  ASIO actual audio playback        : PASS / FAIL")
    $w.WriteLine("  Ordinary reboot persistence       : PASS / FAIL")

    Write-Section $w "END"
    $w.WriteLine("Installed-state evidence capture complete.")
}
finally {
    $w.Dispose()
}

Write-Host ""
Write-Host "Evidence capture complete."
Write-Host "Build/package evidence : $buildOut"
Write-Host "Installed-state evidence: $installedOut"
