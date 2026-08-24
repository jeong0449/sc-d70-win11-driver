# SC-D70 Evidence Capture Tool

`capture-sc-d70-reproduction-evidence.ps1` is a read-only PowerShell script for collecting technical evidence from a prepared and installed Roland SC-D70 Windows 11 test-signing environment.

The script does **not** install, remove, sign, or modify a driver. It only reads the current system and package state and writes the results to text files.

## Requirements

Run the script on Windows 11 using **PowerShell with Administrator privileges**.

Administrator privileges are required so that the script can reliably inspect:

- Windows boot configuration (`bcdedit`);
- the Windows Driver Store (`pnputil`);
- connected PnP devices;
- installed driver files;
- Local Machine certificate stores; and
- ASIO/COM registry entries under `HKLM`.

The script itself is read-only.

## 1. Open PowerShell as Administrator

Open the Start menu, search for:

```text
PowerShell
```

and select:

```text
Run as administrator
```

Confirm the UAC prompt.

The script performs its own Administrator check and will stop if it is not running from an elevated PowerShell session.

## 2. Change to the repository directory

For example:

```powershell
cd C:\projects\SC-D70_Win11-TestSigned\github_sc-d70-windows11
```

If the script is stored under `tools`, you may instead change directly to that directory:

```powershell
cd C:\projects\SC-D70_Win11-TestSigned\github_sc-d70-windows11\tools
```

Adjust the path to match your local repository.

## 3. If PowerShell blocks the script

A PowerShell script downloaded from GitHub, a web browser, or another Internet source may carry a Windows "Mark of the Web" and be blocked by the current PowerShell execution policy.

A typical error is:

```text
PSSecurityException
UnauthorizedAccess
```

with a message stating that the file is not digitally signed.

For this script, it is normally unnecessary to weaken the system-wide PowerShell execution policy.

Instead, explicitly unblock this particular file:

```powershell
Unblock-File .\capture-sc-d70-reproduction-evidence.ps1
```

If the script is under `tools` and you are running the command from the repository root:

```powershell
Unblock-File .\tools\capture-sc-d70-reproduction-evidence.ps1
```

This removes the downloaded-file blocking mark from this file. It does **not** globally change the PowerShell execution policy.

> **Security note:** Only unblock a script after reviewing it and confirming that you trust its source and contents.

## 4. Run the evidence capture

The script accepts three useful parameters:

- `PackagePath` — directory containing the prepared SC-D70 driver package;
- `OutputDir` — directory in which evidence files will be written;
- `CertificateThumbprint` — thumbprint of the local test-signing certificate used for the package.

Example:

```powershell
.\capture-sc-d70-reproduction-evidence.ps1 `
  -PackagePath "C:\projects\SC-D70_Win11-Reproduction" `
  -OutputDir ".\evidence" `
  -CertificateThumbprint "C8E297C15B13589FEFEDBEE13AC498F8CB630B12"
```

If the script is stored in `tools` and the command is run from the repository root:

```powershell
.\tools\capture-sc-d70-reproduction-evidence.ps1 `
  -PackagePath "C:\projects\SC-D70_Win11-Reproduction" `
  -OutputDir ".\evidence" `
  -CertificateThumbprint "C8E297C15B13589FEFEDBEE13AC498F8CB630B12"
```

Replace the package path and certificate thumbprint with the values from your own experiment.

## 5. Output files

The script creates the output directory automatically if necessary.

Two timestamped evidence files are generated:

```text
sc-d70-build-package-YYYYMMDD-HHMMSS.txt
sc-d70-installed-state-YYYYMMDD-HHMMSS.txt
```

For example:

```text
evidence\
├── sc-d70-build-package-20260824-204218.txt
└── sc-d70-installed-state-20260824-204218.txt
```

### Build/package evidence

The `sc-d70-build-package-*.txt` file records information about the prepared driver package, including:

- Windows system information;
- package file list;
- SHA256 hashes of important driver files;
- Authenticode status of `RDWM1012.SYS`;
- Authenticode status of `RDID1012.CAT`;
- selected INF entries;
- signing certificate information; and
- presence of the certificate in relevant Local Machine stores.

This file documents **what package was prepared**.

### Installed-state evidence

The `sc-d70-installed-state-*.txt` file records the actual Windows installation state, including:

- Windows boot configuration and Test Signing state;
- SC-D70 package information from the Driver Store;
- connected SC-D70 physical device;
- Windows Audio and MIDI endpoints;
- installed driver/ASIO files;
- SHA256 hashes of installed files;
- Authenticode status of the installed kernel driver;
- SC-D70 ASIO registry entries;
- ASIO COM registration;
- ASIO 32-bit and 64-bit DLL mappings; and
- certificate trust state.

This file documents **what Windows actually installed and recognized**.

## 6. Functional playback tests are manual

The script intentionally does not claim that audio or MIDI playback works merely because devices or registry entries exist.

The following tests must therefore be performed manually:

```text
Windows USB Audio actual playback
MIDI PART A actual playback
MIDI PART B actual playback
ASIO host loading
ASIO actual audio playback
Ordinary reboot persistence
```

Record those observations in the corresponding experimental or reproduction log.

For example:

```text
docs/reproduction-test-2026-08-24.md
```

This distinction is deliberate:

```text
evidence script
    → machine-observable configuration

reproduction log
    → actual functional observations
```

A registered ASIO DLL, for example, is not by itself proof that an ASIO host successfully opened the driver and streamed audio.

## 7. Recommended repository layout

A useful repository layout is:

```text
sc-d70-windows11/
├── README.md
├── docs/
│   ├── experimental-log-2026-08-23.md
│   ├── experimental-log-2026-08-23-ko.md
│   └── reproduction-test-2026-08-24.md
│
├── tools/
│   ├── README.md
│   └── capture-sc-d70-reproduction-evidence.ps1
│
└── evidence/
    └── 2026-08-24-reproduction/
        ├── sc-d70-build-package-20260824-204218.txt
        └── sc-d70-installed-state-20260824-204218.txt
```

The intended separation is:

```text
tools/     = how evidence was collected
evidence/  = what the machine reported
docs/      = what was done and what the results mean
```

## 8. Before publishing evidence

Review generated evidence files before committing them to a public repository.

The script does not intentionally collect passwords, private keys, or user credentials. However, normal Windows diagnostic output may contain machine-specific identifiers such as:

- PnP device instance IDs;
- MMDEVAPI endpoint GUIDs;
- boot configuration GUIDs; and
- other locally generated Windows identifiers.

These are useful for technical evidence but may be removed if you do not want to publish machine-specific identifiers.

Do not publish:

- private certificate keys;
- exported PFX files containing private keys;
- passwords or credentials;
- unrelated personal information; or
- proprietary Roland driver binaries unless redistribution rights have been established.

The evidence text files contain metadata, hashes, system observations, and diagnostic output rather than redistributed Roland driver binaries.

## 9. Important limitation

This tool is an **evidence-capture tool**, not an installation tool.

It does not reproduce the SC-D70 installation by itself.

In particular, it does not:

```text
create certificates
sign RDWM1012.SYS
run Inf2Cat
sign RDID1012.CAT
modify BCD settings
install a driver package
remove a driver package
modify Secure Boot
modify Memory Integrity
```

Those operations belong to the documented experimental/reproduction procedure.

The purpose of this script is narrower:

> **Capture enough machine-readable evidence to document what was built and what Windows actually installed.**
