# Roland SC-D70 on Windows 11 — Clean-Baseline Reproduction Test

**Date:** 2026-08-24  
**Test system:** Windows 11 Pro x64, build 26200  
**Device:** Roland Sound Canvas SC-D70  
**Original driver:** Roland SC-D70 Windows Vista 64-bit driver  
**Driver version:** 1.0.0.0  
**Driver date:** 2007-01-22  
**USB hardware ID:** `USB\VID_0582&PID_000C`

> [!IMPORTANT]
> ## If this is your first SC-D70 installation on Windows 11
>
> This document records a **clean-baseline reproduction test**, so Sections 3–9 describe the removal and verification of a **previously successful test-signed installation**.
>
> If you are installing the SC-D70 on this Windows system **for the first time**, you do **not** need to perform that cleanup sequence.
>
> Read Sections 1–2 for context, then **skip Sections 3–9 and begin with Section 10, “Creation of a fresh reproduction package.”**
>
> Before starting Section 10, you must already have the original Roland Vista x64 driver package extracted to a local directory. Adjust the example paths in this document to match your own system.
>
> The package-preparation and installation sequence for a first-time installation is therefore:
>
> ```text
> original Roland Vista x64 package
>         ↓
> create a separate working copy
>         ↓
> create a local Code Signing certificate
>         ↓
> test-sign RDWM1012.SYS
>         ↓
> regenerate RDID1012.CAT with Inf2Cat
>         ↓
> test-sign RDID1012.CAT
>         ↓
> enable Windows Test Signing
>         ↓
> reboot
>         ↓
> add RDIF1012.INF to the Driver Store
>         ↓
> connect the SC-D70
>         ↓
> verify Windows Audio / MIDI / ASIO
> ```
>
> The cleanup sections are useful if you are repeating the experiment from a previously modified or test-signed SC-D70 installation and want to establish a verified clean baseline first.

## 1. Purpose

This experiment was a reproduction test of the successful SC-D70 Windows 11 test-signing experiment performed on 2026-08-23.

The purpose was not merely to confirm that the already-installed driver continued to work. The previous successful installation was deliberately removed, Windows was returned to a verified clean baseline with respect to the SC-D70 test installation, and the procedure was repeated from the original Roland Windows Vista x64 driver package.

The central question was:

> Can the successful Windows 11 configuration be recreated from a clean baseline using the original Roland driver package, a newly generated test certificate, and newly signed driver files?

The distinction between the two experiments is therefore:

> **First success = discovery. Second success from a clean baseline = reproducibility.**

The reproduction test was successful.

---

## 2. Previously established result

The 2026-08-23 experiment had already demonstrated that the original Roland SC-D70 Vista x64 driver could function under Windows 11 when appropriately test-signed and loaded in Windows Test Mode.

That experiment confirmed actual operation of:

- the physical Roland SC-D70 MEDIA device;
- Windows USB Audio;
- MIDI PART A;
- MIDI PART B;
- MIDI IN/OUT endpoints;
- ASIO driver registration;
- ASIO host initialization; and
- actual ASIO audio playback.

The persistent successful configuration used:

```text
Secure Boot: OFF
Windows Test Mode: ON
Memory Integrity: ON
```

The purpose of the 2026-08-24 test was to determine whether this result could be reproduced after removing the previous installation.

---

## 3. Starting point: removal of the previous successful installation

Before beginning the reproduction test, the SC-D70 was disconnected from USB.

The previously installed test-signed Driver Store package was identified as:

```text
oem76.inf
```

It was removed using:

```powershell
pnputil /delete-driver oem76.inf /uninstall /force
```

Windows reported that the driver package had been removed and deleted.

A subsequent Driver Store search showed no remaining SC-D70/Roland/`rdif1012` package.

---

## 4. Verification that installed files had been removed

The following installed files from the previous successful configuration were checked:

```text
C:\Windows\System32\drivers\RDWM1012.SYS
C:\Windows\System32\Rdas1012.dll
C:\Windows\SysWOW64\Rdaw1012.dll
C:\Windows\SysWOW64\Rdah1012.dat
```

All returned:

```text
False
```

The previous driver binary and ASIO-related installed files were therefore absent.

---

## 5. Discovery and removal of ASIO/COM registry residue

An important observation was made during cleanup.

Although the Driver Store package and installed files had been removed, the SC-D70 ASIO registry entries remained.

The following keys were still present:

```text
HKLM:\SOFTWARE\ASIO\Roland SC-D70
HKLM:\SOFTWARE\WOW6432Node\ASIO\Roland SC-D70
```

The corresponding COM registration also remained for:

```text
{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
```

These entries referred to ASIO DLLs that had already been removed from the filesystem.

The residual ASIO and CLSID registry entries were manually removed.

After removal, all four relevant locations returned `False`:

```text
HKLM:\SOFTWARE\ASIO\Roland SC-D70
HKLM:\SOFTWARE\WOW6432Node\ASIO\Roland SC-D70
HKLM:\SOFTWARE\Classes\CLSID\{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
```

This demonstrated that:

> `pnputil /delete-driver ... /uninstall` removed the Driver Store package and installed files, but did not remove all SC-D70 ASIO/COM registry entries.

This residue was removed so that the reproduction test would begin from a genuinely clean SC-D70-specific state.

---

## 6. Removal of the previous test certificate

The certificate used for the first successful experiment had the following thumbprint:

```text
18D9858E2CE72AD68A380F3ADBB2B79D6681671B
```

It was removed from:

```text
Cert:\LocalMachine\Root
Cert:\LocalMachine\TrustedPublisher
```

The absence of the certificate from both stores was verified.

---

## 7. Disabling Test Signing and establishing the clean baseline

Windows Test Signing was disabled:

```powershell
bcdedit /set testsigning off
```

The system was rebooted.

After reboot, `bcdedit /enum` showed:

```text
testsigning             No
```

The clean baseline was then verified.

The following conditions were confirmed:

```text
Windows Test Signing                    OFF
Previous test certificate in Root       absent
Previous test certificate in
  TrustedPublisher                      absent
SC-D70 package in Driver Store          absent
RDWM1012.SYS installed                  absent
Rdas1012.dll installed                  absent
Rdaw1012.dll installed                  absent
Rdah1012.dat installed                  absent
SC-D70 ASIO registry entries            absent
SC-D70 CLSID registration               absent
```

Secure Boot remained deliberately **OFF** throughout the reproduction test.

No attempt was made to enable Secure Boot as part of this experiment.

At this point the previous successful SC-D70 installation had been dismantled, and the reproduction test began.

---

## 8. Separation of the previous successful package and the reproduction workspace

The package used in the first successful experiment was preserved at:

```text
C:\projects\SC-D70_Win11-TestSigned
```

It contained the previously test-signed SYS and catalog.

Their SHA256 hashes were verified.

### First-success test-signed SYS

```text
RDWM1012.SYS
SHA256:
410EA76404C9E0C9A700C1248450B2E805E80DF41DBD0D6C2FA86627DC4DF70C
```

### First-success catalog

```text
RDID1012.CAT
SHA256:
949CC7FE428377C4AACB8BE65C08683AE918C827AE26C32C17D3C150DDE025C3
```

These matched the hashes recorded during the first successful experiment.

The preserved original catalog had:

```text
RDID1012_original.CAT
SHA256:
1EB8E95DC22FDD10B9BE330D431C469D5632CC11DDF7FB2674759212A87C1E79
```

To avoid modifying or reusing the first successful package, a separate reproduction workspace was created:

```text
C:\projects\SC-D70_Win11-Reproduction
```

---

## 9. Identification of the original Roland SYS

A search found two copies of `RDWM1012.SYS`:

```text
C:\projects\SC-D70_Win11-TestSigned\RDWM1012.SYS
C:\projects\SC-D70_win_vista_x64\RDWM1012.SYS
```

Their sizes differed:

```text
First-success test-signed SYS : 195096 bytes
Original Roland SYS           : 193664 bytes
```

The SHA256 hash of the original Roland SYS was:

```text
7ADFFEFB2E6B88726DB9428732D704063B87FAD0B4BFF5BCD29C409DB2C2F443
```

This value became the original-binary reference point for the reproduction experiment.

---

## 10. Creation of a fresh reproduction package

The contents of the original Vista x64 package were copied from:

```text
C:\projects\SC-D70_win_vista_x64
```

to:

```text
C:\projects\SC-D70_Win11-Reproduction
```

Example:

```powershell
Copy-Item `
  "C:\projects\SC-D70_win_vista_x64\*" `
  "C:\projects\SC-D70_Win11-Reproduction\" `
  -Recurse
```

The copied `RDWM1012.SYS` was hashed before any signing operation:

```powershell
Get-FileHash `
  "C:\projects\SC-D70_Win11-Reproduction\RDWM1012.SYS" `
  -Algorithm SHA256
```

It returned:

```text
7ADFFEFB2E6B88726DB9428732D704063B87FAD0B4BFF5BCD29C409DB2C2F443
```

This exactly matched the original Roland SYS.

Therefore, the reproduction package was confirmed to have started from the unmodified original driver binary rather than the SYS created during the first experiment.

---

## 11. Creation of a new test certificate

A completely new code-signing certificate was created for the reproduction experiment.

Example:

```powershell
$cert = New-SelfSignedCertificate `
  -Type CodeSigningCert `
  -Subject "CN=SC-D70 Win11 Test Driver" `
  -CertStoreLocation "Cert:\LocalMachine\My" `
  -KeyExportPolicy Exportable `
  -KeySpec Signature `
  -HashAlgorithm SHA256

$cert | Select-Object Subject, Thumbprint, NotBefore, NotAfter
```

The certificate subject was:

```text
CN=SC-D70 Win11 Test Driver
```

The newly generated certificate had the thumbprint:

```text
C8E297C15B13589FEFEDBEE13AC498F8CB630B12
```

This was different from the certificate used in the first successful experiment.

The certificate properties confirmed:

```text
HasPrivateKey     : True
EnhancedKeyUsage : Code Signing
```

The public certificate was exported as:

```powershell
Export-Certificate `
  -Cert $cert `
  -FilePath "C:\projects\SC-D70_Win11-Reproduction\SC-D70-TestDriver.cer"
```

The certificate was then imported into:

```text
Cert:\LocalMachine\Root
Cert:\LocalMachine\TrustedPublisher
```

using:

```powershell
$cer = "C:\projects\SC-D70_Win11-Reproduction\SC-D70-TestDriver.cer"

Import-Certificate `
  -FilePath $cer `
  -CertStoreLocation "Cert:\LocalMachine\Root"

Import-Certificate `
  -FilePath $cer `
  -CertStoreLocation "Cert:\LocalMachine\TrustedPublisher"
```

Its presence in both stores was verified.

This is an important aspect of the reproduction test: the second successful installation did **not** depend on the private key, certificate thumbprint, or already-signed SYS/CAT files from the first experiment.

---

## 12. Re-signing the original RDWM1012.SYS

Immediately before signing, the reproduction copy of `RDWM1012.SYS` was hashed again.

It still returned the original Roland hash:

```text
7ADFFEFB2E6B88726DB9428732D704063B87FAD0B4BFF5BCD29C409DB2C2F443
```

The WDK SignTool used was:

```text
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe
```

An initial signing attempt that selected the certificate only by SHA1 thumbprint failed with:

```text
SignTool Error: No certificates were found that met all the given criteria.
```

The reason was that the newly generated signing certificate resided in:

```text
Cert:\LocalMachine\My
```

SignTool therefore needed to be explicitly directed to the Local Machine `My` certificate store.

The successful command was:

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" sign `
  /v `
  /sm `
  /s My `
  /fd SHA256 `
  /sha1 C8E297C15B13589FEFEDBEE13AC498F8CB630B12 `
  "C:\projects\SC-D70_Win11-Reproduction\RDWM1012.SYS"
```

SignTool reported:

```text
The following certificate was selected:
    Issued to: SC-D70 Win11 Test Driver
    Issued by: SC-D70 Win11 Test Driver
    Expires:   Tue Aug 24 19:59:58 2027
    SHA1 hash: C8E297C15B13589FEFEDBEE13AC498F8CB630B12

Done Adding Additional Store
Successfully signed: C:\projects\SC-D70_Win11-Reproduction\RDWM1012.SYS

Number of files successfully Signed: 1
Number of warnings: 0
Number of errors: 0
```

The practical lesson is:

> When the code-signing certificate is created in `LocalMachine\My`, SignTool must be directed to the machine certificate store, for example with `/sm /s My`.

---

## 13. Verification of the newly signed SYS

PowerShell Authenticode verification returned:

```text
Status     : Valid
Subject    : CN=SC-D70 Win11 Test Driver
Thumbprint : C8E297C15B13589FEFEDBEE13AC498F8CB630B12
```

The SHA256 hash of the newly signed reproduction SYS was:

```text
4A9A9CFE6D79584806E1812D178F2988A58ADB71EB6DD94337E30B5C74F46C3A
```

The three relevant SYS hashes were therefore:

```text
Original Roland SYS:
7ADFFEFB2E6B88726DB9428732D704063B87FAD0B4BFF5BCD29C409DB2C2F443

First-success test-signed SYS:
410EA76404C9E0C9A700C1248450B2E805E80DF41DBD0D6C2FA86627DC4DF70C

Reproduction test-signed SYS:
4A9A9CFE6D79584806E1812D178F2988A58ADB71EB6DD94337E30B5C74F46C3A
```

The two test-signed hashes are expected to differ because they were produced using different newly generated certificates/signatures.

The important point is that both were independently derived from the original Roland driver binary.

---

## 14. Regeneration of the driver catalog

After signing the SYS, the catalog was regenerated.

The WDK `Inf2Cat` executable used was:

```text
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe
```

The command was:

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe" `
  /driver:"C:\projects\SC-D70_Win11-Reproduction" `
  /os:10_X64
```

`Inf2Cat` completed successfully.

The resulting catalog initially had:

```text
Status : NotSigned
```

This was the expected intermediate state: `Inf2Cat` had generated a catalog corresponding to the newly signed SYS, but the catalog itself had not yet been test-signed.

---

## 15. Signing the regenerated catalog

The regenerated `RDID1012.CAT` was signed using the same new reproduction certificate:

```powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" sign `
  /v `
  /sm `
  /s My `
  /fd SHA256 `
  /sha1 C8E297C15B13589FEFEDBEE13AC498F8CB630B12 `
  "C:\projects\SC-D70_Win11-Reproduction\RDID1012.CAT"
```

SignTool reported:

```text
Successfully signed:
C:\projects\SC-D70_Win11-Reproduction\RDID1012.CAT

Number of files successfully Signed: 1
Number of warnings: 0
Number of errors: 0
```

Authenticode verification then returned:

```text
Status     : Valid
Subject    : CN=SC-D70 Win11 Test Driver
Thumbprint : C8E297C15B13589FEFEDBEE13AC498F8CB630B12
```

The final reproduction catalog SHA256 was:

```text
6671DDD130C28F4B7E6113033B8CBB50CEECCE7EF8224BEABCCEFE4FD4D98B17
```

At this point both:

```text
RDWM1012.SYS
RDID1012.CAT
```

were independently recreated and carried valid signatures from the newly generated reproduction certificate.

---

## 16. Enabling Windows Test Signing

Windows Test Signing was enabled:

```powershell
bcdedit /set testsigning on
```

Windows reported that the operation completed successfully.

The system was rebooted.

After reboot:

```powershell
bcdedit /enum
```

showed:

```text
testsigning             Yes
```

The test-signing boot environment was therefore active.

Secure Boot remained **OFF**.

---

## 17. Adding the newly prepared package to the Driver Store

With the SC-D70 still disconnected, the newly prepared reproduction INF was added to the Windows Driver Store:

```powershell
pnputil /add-driver "C:\projects\SC-D70_Win11-Reproduction\RDIF1012.INF"
```

Windows reported:

```text
드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다.
게시된 이름:         oem76.inf

총 드라이버 패키지:  1
추가된 드라이버 패키지:  1
```

Interestingly, Windows assigned the package the same published name used during the first successful experiment:

```text
oem76.inf
```

This matching number was not required for success, but it was observed.

Driver Store enumeration showed:

```text
게시된 이름:     oem76.inf
원래 이름:       rdif1012.inf
공급자 이름:     Roland
클래스 이름:     MEDIA
클래스 GUID:     {4d36e96c-e325-11ce-bfc1-08002be10318}
드라이버 버전:   01/22/2007 1.0.0.0
서명자 이름:     SC-D70 Win11 Test Driver
특성:            Legacy
```

This confirmed that Windows had accepted the reproduced package while preserving the original Roland driver identity and version.

---

## 18. Connecting the SC-D70

The SC-D70 was then connected by USB.

No additional `/install` operation was performed.

Windows automatically matched the connected device to the package already present in the Driver Store.

PnP enumeration showed:

```text
인스턴스 ID:
USB\VID_0582&PID_000C\6&197fd1e3&0&4

장치 설명:
Roland SC-D70

클래스 이름:
MEDIA

제조업체 이름:
Roland

상태:
시작됨

드라이버 이름:
oem76.inf
```

The hardware IDs included:

```text
USB\VID_0582&PID_000C&REV_0100
USB\VID_0582&PID_000C
```

This was an important practical result:

> Adding the prepared package to the Driver Store before connecting the SC-D70 was sufficient. When the device was connected, Windows automatically bound it to the reproduced `oem76.inf` package.

---

## 19. Device and endpoint enumeration

PowerShell PnP enumeration showed:

```text
Status   Class           FriendlyName
------   -----           ------------
OK       AudioEndpoint   IN(Roland SC-D70)
OK       AudioEndpoint   OUT(Roland SC-D70)
OK       MEDIA           Roland SC-D70
Unknown  MidiEndpoint    Roland SC-D70
Unknown  SoftwareDevice  Roland SC-D70
Unknown  SoftwareDevice  Roland SC-D70 MIDI IN
Unknown  SoftwareDevice  Roland SC-D70 MIDI OUT
Unknown  SoftwareDevice  Roland SC-D70 PART A
Unknown  SoftwareDevice  Roland SC-D70 PART B
```

The `Unknown` status shown for the newer MIDI service/software-device layer was not treated as evidence of failure. Actual MIDI playback was tested separately.

The physical MEDIA device and Windows audio endpoints reported `OK`.

---

## 20. Windows USB Audio functional test

Windows audio output was directed to:

```text
OUT(Roland SC-D70)
```

Google Chrome was used to play YouTube audio.

Actual audible output through the SC-D70 was confirmed.

Therefore:

```text
Windows USB Audio enumeration : PASS
Windows USB Audio playback    : PASS
```

This was a functional playback test, not merely an endpoint-enumeration test.

---

## 21. MIDI PART A and PART B functional test

Both SC-D70 MIDI parts were tested with actual MIDI playback.

The MIDI output endpoints:

```text
Roland SC-D70 PART A
Roland SC-D70 PART B
```

both produced actual audible MIDI playback through the SC-D70.

During the reproduction test, the system was used to play **Kim Carnes — "Bette Davis Eyes"** through the SC-D70.

Therefore:

```text
MIDI PART A : PASS
MIDI PART B : PASS
```

This reproduced the MIDI functionality observed during the first successful experiment.

---

## 22. ASIO registry restoration

The SC-D70 ASIO and COM registry entries had been explicitly removed during establishment of the clean baseline.

After installing the reproduced package and connecting the device, all four relevant registry locations existed again:

```text
HKLM:\SOFTWARE\ASIO\Roland SC-D70
HKLM:\SOFTWARE\WOW6432Node\ASIO\Roland SC-D70
HKLM:\SOFTWARE\Classes\CLSID\{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
HKLM:\SOFTWARE\Classes\WOW6432Node\CLSID\{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
```

All returned:

```text
True
```

This demonstrated that the SC-D70 installation recreated the ASIO/COM registration that had been deliberately removed before the reproduction test.

---

## 23. ASIO COM mapping

The ASIO CLSID was:

```text
{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
```

The reproduced COM registration resolved to:

```text
ASIO64:
\\?\C:\WINDOWS\system32\Rdas1012.dll

ASIO32:
\\?\C:\WINDOWS\system32\Rdaw1012.dll
```

The `\\?\` prefix is a Windows path representation; the effective file targets correspond to the same Roland ASIO components observed during the first successful experiment.

---

## 24. Verification of installed ASIO binaries

The installed ASIO-related files were hashed.

### `Rdas1012.dll`

```text
C:\Windows\System32\Rdas1012.dll

SHA256:
C56396ACC92965013CB2F034EFB6598A2A135FBFBC3E518C726B22CBB8E43305
```

### `Rdaw1012.dll`

```text
C:\Windows\SysWOW64\Rdaw1012.dll

SHA256:
B9E3A0EA9CF6CA65EF3B10CA5C8332EEB75E488AD7B5596C1A3F87DC3433BEED
```

### `Rdah1012.dat`

```text
C:\Windows\SysWOW64\Rdah1012.dat

SHA256:
DC9748A2759BDBDD149C4F9A25A60E9D3515AF5FA5818AAD9BF716ABA052B508
```

All three hashes exactly matched the corresponding files recorded during the first successful experiment.

This confirmed that the same original Roland user-mode ASIO components had been installed during the reproduction.

---

## 25. Actual ASIO playback test

ASIO functionality was tested using **Waveform** with an existing audio project.

The Roland SC-D70 ASIO driver loaded successfully and the existing project played normally through the SC-D70.

This was an actual streaming test.

Therefore:

```text
ASIO registry presence       : PASS
ASIO COM registration        : PASS
ASIO DLL installation        : PASS
ASIO host loading            : PASS
Actual ASIO audio playback   : PASS
```

The first experiment had previously observed operation at:

```text
48,000 Hz
480 samples
10.0 ms
```

The reproduction test confirmed actual ASIO playback. The purpose of this test was functional reproduction of the working ASIO configuration rather than merely verifying registry entries.

---

## 26. Final reboot-persistence test

After Windows Audio, MIDI PART A/B, and ASIO had all been demonstrated to work, one final ordinary Windows reboot was performed.

The SC-D70 remained installed.

No driver reconstruction or special one-boot signature bypass was performed after this reboot.

Following the reboot, the following functional tests were repeated.

### Windows Audio

YouTube playback through the SC-D70:

```text
PASS
```

### MIDI

```text
MIDI PART A : PASS
MIDI PART B : PASS
```

### ASIO

Actual ASIO output:

```text
PASS
```

Thus, the reproduced installation survived an ordinary reboot and remained fully functional.

---

## 27. Reproduction result

The final reproduction result was:

| Test | Result |
|---|---|
| Verified clean SC-D70 baseline | **PASS** |
| Previous test certificate removed | **PASS** |
| Previous Driver Store package removed | **PASS** |
| Previous installed SYS/ASIO files removed | **PASS** |
| Previous ASIO/COM registry residue removed | **PASS** |
| Test Signing disabled and verified before reproduction | **PASS** |
| Reproduction started from original Roland SYS | **PASS** |
| New independent test certificate generated | **PASS** |
| Original `RDWM1012.SYS` re-signed | **PASS** |
| Re-signed SYS Authenticode status | **Valid** |
| Catalog regenerated with `Inf2Cat` | **PASS** |
| New catalog test-signed | **PASS** |
| Catalog Authenticode status | **Valid** |
| Test Signing re-enabled | **PASS** |
| Reproduced package accepted into Driver Store | **PASS** |
| Physical SC-D70 device | **Started / PASS** |
| Windows Audio endpoint creation | **PASS** |
| Windows Audio actual playback | **PASS** |
| MIDI PART A actual playback | **PASS** |
| MIDI PART B actual playback | **PASS** |
| ASIO registry recreation | **PASS** |
| ASIO COM mapping recreation | **PASS** |
| Installed ASIO binary hashes match first experiment | **PASS** |
| ASIO host loading | **PASS** |
| Actual ASIO playback | **PASS** |
| Ordinary reboot persistence | **PASS** |

---

## 28. Key hashes from the reproduction experiment

### Original Roland `RDWM1012.SYS`

```text
7ADFFEFB2E6B88726DB9428732D704063B87FAD0B4BFF5BCD29C409DB2C2F443
```

### First-success test-signed `RDWM1012.SYS`

```text
410EA76404C9E0C9A700C1248450B2E805E80DF41DBD0D6C2FA86627DC4DF70C
```

### Reproduction test-signed `RDWM1012.SYS`

```text
4A9A9CFE6D79584806E1812D178F2988A58ADB71EB6DD94337E30B5C74F46C3A
```

### First-success `RDID1012.CAT`

```text
949CC7FE428377C4AACB8BE65C08683AE918C827AE26C32C17D3C150DDE025C3
```

### Reproduction `RDID1012.CAT`

```text
6671DDD130C28F4B7E6113033B8CBB50CEECCE7EF8224BEABCCEFE4FD4D98B17
```

### Preserved original catalog

```text
1EB8E95DC22FDD10B9BE330D431C469D5632CC11DDF7FB2674759212A87C1E79
```

---

## 29. Certificate independence

The first successful experiment used:

```text
Subject:
CN=SC-D70 Win11 Test Driver

Thumbprint:
18D9858E2CE72AD68A380F3ADBB2B79D6681671B
```

The reproduction experiment used a newly generated certificate:

```text
Subject:
CN=SC-D70 Win11 Test Driver

Thumbprint:
C8E297C15B13589FEFEDBEE13AC498F8CB630B12
```

The successful reproduction therefore did not depend on retaining the certificate or signed driver binaries created during the first experiment.

This is one of the strongest pieces of evidence that the procedure itself, rather than a particular first-run artifact, is reproducible.

---

## 30. Practical lessons confirmed by the reproduction

### 30.1 Sign the SYS before generating the final catalog

The working sequence is:

```text
original RDWM1012.SYS
        ↓
test-sign RDWM1012.SYS
        ↓
generate/regenerate RDID1012.CAT with Inf2Cat
        ↓
test-sign RDID1012.CAT
```

Signing the SYS changes the binary. The final catalog must therefore correspond to the signed SYS.

### 30.2 SignTool must search the correct certificate store

When the signing certificate is stored in:

```text
LocalMachine\My
```

the successful SignTool invocation explicitly included:

```text
/sm /s My
```

Without the appropriate store selection, SignTool reported that no matching certificate could be found.

### 30.3 Driver Store staging can precede device connection

The reproduced package was added to the Driver Store while the SC-D70 was disconnected.

After the device was connected, Windows automatically selected:

```text
oem76.inf
```

and the physical MEDIA device entered the `Started` state.

No additional `pnputil /install` operation was required during this reproduction sequence.

### 30.4 Removing the Driver Store package does not necessarily remove ASIO/COM residue

During establishment of the clean baseline, the Driver Store package and installed files had been removed, but SC-D70 ASIO and CLSID registry entries remained.

For a rigorous clean-baseline reproduction test, these entries had to be checked and removed separately.

### 30.5 Device enumeration is not sufficient as a functional test

The reproduction test did not stop at Device Manager/PnP enumeration.

Actual functional tests were performed for:

```text
Windows Audio
MIDI PART A
MIDI PART B
ASIO
```

All produced actual audible output.

### 30.6 Reboot persistence matters

A driver configuration that works only during the installation session would not demonstrate a persistent solution.

The final reproduction therefore included another ordinary reboot followed by repeated Windows Audio, MIDI, and ASIO playback tests.

All remained functional.

---

## 31. What this reproduction demonstrates

This experiment demonstrates that the successful 2026-08-23 result was not merely an accidental state produced by exploratory trial and error.

The following sequence was independently repeated:

```text
verified clean baseline
        ↓
original Roland Vista x64 package
        ↓
new independent test certificate
        ↓
test-sign original SYS
        ↓
regenerate catalog
        ↓
test-sign catalog
        ↓
enable Windows Test Signing
        ↓
stage package in Driver Store
        ↓
connect SC-D70
        ↓
automatic driver binding
        ↓
Windows Audio
        ↓
MIDI PART A / PART B
        ↓
ASIO
        ↓
ordinary reboot
        ↓
Windows Audio / MIDI / ASIO still working
```

The result was successful.

---

## 32. What this reproduction does not demonstrate

This experiment does **not** demonstrate:

- compatibility with Secure Boot enabled;
- operation with Windows Test Signing disabled;
- Microsoft production signing;
- an official Roland Windows 11 driver;
- a newly developed replacement driver;
- compatibility with every Windows 11 build or hardware platform; or
- suitability of Test Mode as a permanent security configuration.

The successful environment still used:

```text
Secure Boot: OFF
Windows Test Mode: ON
Memory Integrity: ON
```

The experiment should therefore be understood as a technically successful compatibility and reproducibility demonstration, not as a production driver-signing solution.

---

## 33. Conclusion

The original **Roland SC-D70 Windows Vista x64 driver, version 1.0.0.0 dated 2007-01-22**, was successfully brought back into functional use on Windows 11 x64 for a second time.

Unlike the first experiment, the second test began from a verified clean SC-D70-specific Windows baseline.

The previous Driver Store package, installed driver files, ASIO components, ASIO/COM registry entries, and test certificate were removed. Windows Test Signing was disabled and the clean state was verified.

The experiment then returned to the original Roland Vista x64 package.

A new and independent code-signing certificate was generated. The original Roland `RDWM1012.SYS` was newly test-signed, a corresponding catalog was regenerated and test-signed, Windows Test Signing was enabled, and the resulting package was staged in the Driver Store.

When the SC-D70 was connected, Windows automatically bound the device to the newly prepared driver package.

Actual functional tests then confirmed:

```text
Windows USB Audio : PASS
MIDI PART A       : PASS
MIDI PART B       : PASS
ASIO playback     : PASS
```

After a final ordinary reboot:

```text
Windows USB Audio : PASS
MIDI PART A       : PASS
MIDI PART B       : PASS
ASIO playback     : PASS
```

The central conclusion is therefore:

> **The 2026-08-23 result was reproducible from a clean baseline using the original Roland driver package and a newly generated test-signing identity.**

Or, more simply:

> **First success = discovery. Second success from a clean baseline = reproducibility.**
