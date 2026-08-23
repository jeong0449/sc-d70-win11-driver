# Roland SC-D70 on Windows 11 --- Experimental Log

**Date:** 2026-08-23\
**Device:** Roland SC-D70\
**Original driver:** Roland SC-D70 Windows Vista 64-bit driver, version
1.0.0.0, dated 2007-01-22\
**Host:** Windows 11 x64\
**Scope:** Audited against the commands, outputs, and explicit success
reports preserved in the 2026-08-23 ChatGPT conversation.

> This edition deliberately separates the experimental record from a
> reconstructed how-to guide. **\[CONFIRMED: command+output\]** means
> that the user posted both the command and its output. **\[CONFIRMED:
> result\]** means that the user explicitly reported the result but the
> complete command/output is not preserved in the visible transcript.
> **\[REPRODUCTION / command not transcript-confirmed\]** marks commands
> useful for reproducing the experiment but not preserved as exact
> user-entered commands in the available transcript.
> **\[INTERPRETATION\]** marks technical interpretation.

## 1. Two experiments

The first experiment asked whether the original 2007 Vista 64-bit driver
still functioned on Windows 11. The package could be added to the Driver
Store, but the device did not load normally. Code 39 was observed at one
stage and Code 52 (`CM_PROB_UNSIGNED_DRIVER`) was later recorded. After
Driver Signature Enforcement was disabled for one boot, the SC-D70
operated, including MIDI PART A, MIDI PART B, and Windows USB Audio.

The second experiment asked whether the same old driver could be made
persistent across ordinary reboots using Windows' test-signing
mechanism. Current WDK tools were used to generate a catalog and
inspect/sign the driver package. The final working state was Secure Boot
OFF, Windows Test Mode ON, and Memory Integrity ON. The SC-D70 remained
functional after an ordinary reboot.

No new functional SC-D70 driver was developed. The experiment reused the
original Roland driver binary and changed its signing/package trust
context.

------------------------------------------------------------------------

# Part I --- Original Vista 64-bit driver

## 2. Installing the INF

### Non-elevated attempt

**\[CONFIRMED: command+output\]**

``` powershell
pnputil /add-driver RDIF1012.INF /install
```

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가하지 못함: 액세스가 거부되었습니다.

총 드라이버 패키지:  1
추가된 드라이버 패키지:  0
```

### Elevated attempt

**\[CONFIRMED: command+output\]**

``` powershell
pnputil /add-driver RDIF1012.INF /install
```

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다.
게시된 이름:         oem76.inf
드라이버 패키지가 장치에 설치됨: USB\VID_0582&PID_000C\6&197fd1e3&0&4

총 드라이버 패키지:  1
추가된 드라이버 패키지:  1
```

`oem76.inf` was the published name on this particular PC.

## 3. PnP status

**\[CONFIRMED: command+output\]**

``` powershell
Get-PnpDevice | Where-Object {
    $_.FriendlyName -match "SC-D70|Roland"
} | Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
```

``` text
Status Class FriendlyName  InstanceId
------ ----- ------------  ----------
Error  MEDIA Roland SC-D70 USB\VID_0582&PID_000C\6&197FD1E3&0&4
```

At one point the detailed device state reported:

``` text
문제 코드: 39 (0x27) [CM_PROB_DRIVER_FAILED_LOAD]
문제 상태: 0xC000007B
```

A later detailed query was explicitly posted:

``` powershell
pnputil /enum-devices /instanceid "USB\VID_0582&PID_000C\6&197fd1e3&0&4" /drivers /services
```

with the key result:

``` text
문제 코드:               52 (0x34) [CM_PROB_UNSIGNED_DRIVER]
문제 상태:               0xC0000428
드라이버 이름:            oem76.inf
서비스:                   RDID1012
...
드라이버 버전:            01/22/2007 1.0.0.0
서명자 이름:              Roland Corporation
일치하는 장치 ID:         USB\VID_0582&PID_000C
드라이버 상태:            최고 순위 / 설치됨
```

**\[INTERPRETATION\]** Installation and loading were distinct: the
package was present, but Windows refused to load the device normally.
Code 52 directly implicated signature enforcement.

## 4. One-boot signature-enforcement bypass

**\[CONFIRMED: result\]** The experiment used Windows Startup Settings
to disable Driver Signature Enforcement for one boot. The subsequent
device output posted by the user was:

``` text
Status Class         FriendlyName       InstanceId
------ -----         ------------       ----------
OK     AudioEndpoint IN(Roland SC-D70)  SWD\MMDEVAPI\...
OK     MEDIA         Roland SC-D70      USB\VID_0582&PID_000C\6&197FD1E3&0&4
OK     AudioEndpoint OUT(Roland SC-D70) SWD\MMDEVAPI\...
```

The user then explicitly confirmed that both A and B ports worked and
that SC-D70 appeared in Windows Sound and produced audio normally.

## 5. Memory Integrity restored

**\[CONFIRMED: result\]** After Memory Integrity was turned back ON and
the relevant reboot was performed, the user reported no error, working
USB Audio, and both MIDI ports present. The posted device list included:

``` text
OK  MidiEndpoint    Roland SC-D70
OK  SoftwareDevice Roland SC-D70
OK  SoftwareDevice Roland SC-D70 MIDI IN
OK  SoftwareDevice Roland SC-D70 PART A
OK  SoftwareDevice Roland SC-D70 PART B
OK  SoftwareDevice Roland SC-D70 MIDI OUT
OK  AudioEndpoint  IN(Roland SC-D70)
OK  MEDIA          Roland SC-D70
OK  AudioEndpoint  OUT(Roland SC-D70)
```

**Part I finding:** the original Vista 64-bit driver remained
functionally capable of operating the SC-D70 under Windows 11 when
Windows allowed it to load. Memory Integrity did not need to remain
disabled.

------------------------------------------------------------------------

# Part II --- Test-signing experiment

## 6. Tool discovery

**\[CONFIRMED: command+output\]**

Initial checks:

``` powershell
where.exe signtool.exe
where.exe inf2cat.exe
where.exe makecert.exe
Confirm-SecureBootUEFI
bcdedit /enum | findstr /i "testsigning"
```

The three `where.exe` commands initially found nothing.
`Confirm-SecureBootUEFI` returned:

``` text
True
```

The `testsigning` filter produced no visible line at that stage.

A recursive SDK search later found several SignTool copies, including:

``` text
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe
```

After WDK installation, Inf2Cat was found at:

``` text
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe
```

## 7. Working directory

**\[CONFIRMED: output\]**

The working directory was:

``` text
C:\projects\SC-D70_Win11-TestSigned
```

The user posted a directory listing containing the original package
files, including:

``` text
RDID1012.CAT       9953
RDIF1012.INF      13470
RDWM1012.SYS     193664
Setup.exe        1532728
Uninstal.exe      398136
```

The earlier document presented
`Rename-Item .\RDID1012.CAT RDID1012_original.CAT` as an executed
transcript step. That exact command/output is not preserved in the
currently visible user messages, so this audited edition does not claim
it as confirmed execution.

## 8. Inf2Cat

**\[CONFIRMED: command+output\]**

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe" `
  /driver:"C:\projects\SC-D70_Win11-TestSigned" `
  /os:10_X64
```

``` text
..........................................
Signability test complete.

Errors:
None

Warnings:
None

Catalog generation complete.
C:\projects\SC-D70_Win11-TestSigned\rdid1012.cat
```

This is one of the strongest directly preserved results of the signing
experiment.

## 9. Test certificate

**\[CONFIRMED: result\]**

The user posted:

``` powershell
$cert | Format-List Subject,Thumbprint,NotBefore,NotAfter,HasPrivateKey
```

with:

``` text
Subject       : CN=SC-D70 Win11 Test Driver
Thumbprint    : 18D9858E2CE72AD68A380F3ADBB2B79D6681671B
NotBefore     : 2026-08-23 오후 7:07:23
NotAfter      : 2027-08-23 오후 7:27:23
HasPrivateKey : True
```

**\[REPRODUCTION / command not transcript-confirmed\]** The exact
`New-SelfSignedCertificate`, export, and trust-store import commands
shown in the earlier document were reconstructed as a how-to. Their
complete user-entered commands and outputs are not preserved in the
currently visible transcript. The certificate's existence and
properties, however, are directly confirmed by the output above.

## 10. Original SYS signature check

**\[CONFIRMED: command+output\]**

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" `
  verify /v /kp .\RDWM1012.SYS
```

Before test-signing:

``` text
Verifying: .\RDWM1012.SYS
SignTool Error: No signature found.

Number of files successfully Verified: 0
Number of warnings: 0
Number of errors: 1
```

After the signing step, the user posted the same verification with a
very different result:

``` text
Signature Index: 0 (Primary Signature)
Hash of file (sha256): 40E97DAAAA6A19820A1EE8E70AC77449F5977FCEFF069D3471B31F80346D7826

Signing Certificate Chain:
    Issued to: SC-D70 Win11 Test Driver
    Issued by: SC-D70 Win11 Test Driver
    Expires:   Mon Aug 23 19:27:23 2027
    SHA1 hash: 18D9858E2CE72AD68A380F3ADBB2B79D6681671B

File is not timestamped.

SignTool Error: A certificate chain processed, but terminated in a root
        certificate which is not trusted by the trust provider.
```

**\[INTERPRETATION\]** The transition from `No signature found` to a
primary signature issued to the test certificate confirms that the SYS
had acquired an embedded test signature.

The exact `signtool sign ... RDWM1012.SYS` command is not present in the
currently visible user transcript and is therefore not presented here as
a confirmed user-entered command.

## 11. CAT signature check

**\[CONFIRMED: command+output\]**

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" `
  verify /v .\RDID1012.CAT
```

The user posted:

``` text
Signature Index: 0 (Primary Signature)
Hash of file (sha256): B0642075B816C31E4DAF54A08F428C0AB0C64752F918BA47051C11043E19B036

Signing Certificate Chain:
    Issued to: SC-D70 Win11 Test Driver
    Issued by: SC-D70 Win11 Test Driver
    Expires:   Mon Aug 23 19:27:23 2027
    SHA1 hash: 18D9858E2CE72AD68A380F3ADBB2B79D6681671B

File is not timestamped.

SignTool Error: A certificate chain processed, but terminated in a root
        certificate which is not trusted by the trust provider.

Number of files successfully Verified: 0
Number of warnings: 0
Number of errors: 1
```

The user subsequently reported that **both verification commands showed
zero errors**.

The earlier document reconstructed those final checks as `/pa` commands.
Since the exact final commands are not preserved in the currently
visible user transcript, this edition records only the confirmed result:
both later checks returned error count 0.

## 12. Package-order lesson

**\[INTERPRETATION / reproduction guidance\]**

Because adding an embedded signature changes the SYS file, a final
catalog must describe the already-signed SYS. The technically correct
order is therefore:

``` text
test-sign SYS
      ↓
generate/regenerate CAT
      ↓
test-sign CAT
```

This ordering is important for reproduction, but individual intermediate
commands such as `Remove-Item .\RDID1012.CAT` should not be mistaken for
verbatim user transcript unless separately preserved.

## 13. BitLocker

**\[CONFIRMED: command+output\]**

``` powershell
manage-bde -status C:
```

Key output:

``` text
BitLocker 버전:       없음
변환 상태:            완전 암호 해독됨
암호화된 비율:        0.0%
암호화 방법:          없음
보호 상태:            보호 해제
잠금 상태:            잠금 해제됨
키 보호기:            없음
```

This PC did not have BitLocker enabled on C:.

## 14. Secure Boot

**\[CONFIRMED: command+output/result\]**

Before the firmware change:

``` powershell
Confirm-SecureBootUEFI
```

returned:

``` text
True
```

A non-elevated attempt to enter firmware setup:

``` powershell
shutdown /r /fw /t 0
```

returned:

``` text
클라이언트가 필요한 권한을 가지고 있지 않습니다.(1314)
```

After the UEFI change, the user explicitly reported that
`Confirm-SecureBootUEFI` showed:

``` text
False
```

The earlier document stated that the `/fw` command was then rerun as
Administrator. That is plausible and consistent with the workflow, but
the exact rerun is not preserved in the visible user transcript, so it
is not claimed here as a confirmed command.

## 15. Windows Test Mode

**\[CONFIRMED: result\]** The final experiment clearly ran in Windows
Test Mode; after success the user specifically asked why Windows
displayed Test Mode.

**\[REPRODUCTION / command not transcript-confirmed\]** The exact
`bcdedit /set testsigning on` and subsequent reboot/status-check
commands shown in the earlier document are reproduction commands, not
verbatim user-entered transcript in the currently visible record.

## 16. First installation attempt reused the old package

**\[CONFIRMED: command+output\]**

``` powershell
pnputil /add-driver .\RDIF1012.INF /install
```

``` text
드라이버 패키지를 추가했습니다. (시스템에 이미 있음)
게시된 이름:         oem76.inf
드라이버 패키지가 장치에서 최신 상태임:USB\VID_0582&PID_000C\6&197fd1e3&0&4

총 드라이버 패키지:  1
추가된 드라이버 패키지:  0
```

The detailed device query still showed:

``` text
문제 코드:               52 (0x34) [CM_PROB_UNSIGNED_DRIVER]
문제 상태:               0xC0000428
드라이버 이름:            oem76.inf
서명자 이름:              Roland Corporation
```

The PnP summary showed the physical MEDIA device as `Error`.

**\[INTERPRETATION\]** The newly prepared package had not actually
displaced the old Driver Store package.

## 17. Adding the new package after the old package was dealt with

**\[CONFIRMED: command+output\]**

The user later posted:

``` powershell
pnputil /add-driver .\RDIF1012.INF
```

with:

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다.
게시된 이름:         oem76.inf

총 드라이버 패키지:  1
추가된 드라이버 패키지:  1
```

**\[REPRODUCTION / command not transcript-confirmed\]** The earlier
document showed:

``` powershell
pnputil /delete-driver oem76.inf /uninstall /force
```

as the exact removal command. The workflow did include
removal/replacement of the old package, but the exact delete command and
its output are not preserved in the currently visible user messages.
This audited edition therefore does not present that line as a confirmed
user-entered command.

## 18. Final device state

**\[CONFIRMED: command+output\]**

``` powershell
Get-PnpDevice |
  Where-Object {$_.FriendlyName -match "SC-D70|Roland"} |
  Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
```

``` text
Status  Class          FriendlyName           InstanceId
------  -----          ------------           ----------
Unknown MidiEndpoint   Roland SC-D70          SWD\MIDISRV\MIDIU_KSA_7685147921777411643
Unknown SoftwareDevice Roland SC-D70          SWD\MMDEVAPI\MIDIU_KSA_7685147921777411643_0_0
Unknown SoftwareDevice Roland SC-D70 MIDI IN  SWD\MMDEVAPI\MIDIU_KSA_7685147921777411643_0_1
Unknown SoftwareDevice Roland SC-D70 PART A   SWD\MMDEVAPI\MIDIU_KSA_7685147921777411643_1_0
Unknown SoftwareDevice Roland SC-D70 PART B   SWD\MMDEVAPI\MIDIU_KSA_7685147921777411643_1_1
Unknown SoftwareDevice Roland SC-D70 MIDI OUT SWD\MMDEVAPI\MIDIU_KSA_7685147921777411643_1_2
OK      AudioEndpoint  IN(Roland SC-D70)      SWD\MMDEVAPI\{0.0.1.00000000}.{76C072EE-B6AC-4BB6-A588-A230EFF86FB1}
OK      MEDIA          Roland SC-D70          USB\VID_0582&PID_000C\6&197FD1E3&0&4
OK      AudioEndpoint  OUT(Roland SC-D70)     SWD\MMDEVAPI\{0.0.0.00000000}.{DFB08F04-01EE-4080-BCA7-11DF4A240ED5}
```

The user explicitly confirmed that the device worked normally and then
rebooted.

## 19. Ordinary reboot

**\[CONFIRMED: result\]** After the ordinary reboot, the user reported
that it worked perfectly and asked why Windows displayed Test Mode. The
final experimentally confirmed state was therefore:

``` text
SC-D70 physical MEDIA device: working
USB Audio: working
MIDI PART A: working
MIDI PART B: working
Memory Integrity: ON
Secure Boot: OFF
Windows Test Mode: ON
Persistence across ordinary reboot: confirmed
```

The transcript does not establish whether the ordinary reboot itself was
initiated by `shutdown /r /t 0` or by the Windows UI, so this edition
does not claim a specific reboot command.

------------------------------------------------------------------------

# 20. Reproduction summary

For a future reproduction, the technical sequence inferred from the
successful experiment is:

``` text
original Vista 64-bit package
        ↓
prepare a test code-signing certificate
        ↓
test-sign RDWM1012.SYS
        ↓
generate/regenerate catalog against the signed SYS
        ↓
test-sign the catalog
        ↓
disable Secure Boot
        ↓
enable Windows Test Signing
        ↓
remove/replace the old SC-D70 Driver Store package
        ↓
add the test-signed package
        ↓
verify MIDI and USB Audio
        ↓
ordinary reboot and verify again
```

Machine-specific values such as `oem76.inf` and the certificate
thumbprint must never be copied blindly to another PC.

# 21. Security and distribution note

The persistent successful configuration used Secure Boot OFF and Windows
Test Mode ON. Memory Integrity remained ON, but this is not equivalent
to a normal production Windows 11 trust configuration.

This repository should document the experiment rather than redistribute
Roland's original or modified binaries unless redistribution rights are
established.

# 22. Conclusion

The 2026-08-23 experiment demonstrated that the 2007 Roland SC-D70 Vista
64-bit driver remains functionally usable on Windows 11 when Windows
permits it to load. A test-signed package was subsequently made to work
across an ordinary reboot in Windows Test Mode. The most accurate
description is therefore a **reproducible test-signed compatibility
configuration**, not a new or production-signed Windows 11 driver.
