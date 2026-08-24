# Roland SC-D70 on Windows 11

This repository documents an experiment conducted on 2026-08-23 to use the original **Roland SC-D70 Windows Vista 64-bit driver (1.0.0.0, 2007-01-22)** on Windows 11 x64.

The main result is simple: the old driver still works functionally. When
Windows was made to accept it, the SC-D70 provided working **USB Audio,
MIDI PART A, MIDI PART B, and ASIO audio**. A second experiment
test-signed the old driver package so that it continued to work after an
ordinary reboot in Windows Test Mode.

The ASIO component was not merely present in the registry. The original
Vista x64 package installs `Rdas1012.dll` as its ASIO component; Windows
11 registered **Roland SC-D70** with CLSID
`{4C258F3C-BDB2-4183-A5B5-C2BB845B426B}`, whose `InprocServer32` pointed
to `C:\Windows\System32\Rdas1012.dll`. An ASIO host successfully opened
the driver at **48,000 Hz / 480 samples (10.0 ms)**, and actual audio
playback was confirmed.

No new functional SC-D70 driver was written.

## Original Vista 64-bit driver

The original Roland package used in this experiment was available at:

``` text
http://lib.roland.co.jp/support/en/downloads/res/1812426/SC-D70_win_vista_x64.zip
```

As verified on **2026-08-23**, this legacy download worked over **HTTP,
not HTTPS**. Replacing `http://` with `https://` did not yield a working
download. The HTTP form is therefore preserved here deliberately rather
than being an accidental omission of HTTPS.

Because this is a legacy vendor URL, its future availability is not
guaranteed. This repository documents the source URL but does not
redistribute the Roland driver package.

## Results

The original package could be installed into the Windows Driver Store,
but the device did not load normally. The experiment recorded:

``` text
52 (0x34) [CM_PROB_UNSIGNED_DRIVER]
0xC0000428
```

Temporarily disabling Driver Signature Enforcement for one boot allowed
the device to operate. The experiment then verified both MIDI parts and
Windows USB Audio.

The test-signing experiment used WDK 10.0.28000.0 tools. `Inf2Cat`
processed the package with:

``` text
Errors:
None

Warnings:
None
```

The original `RDWM1012.SYS` initially produced:

``` text
SignTool Error: No signature found.
```

After the signing work, SignTool showed a primary signature issued to
the locally created `SC-D70 Win11 Test Driver` certificate. The catalog
carried the same test certificate.

After the old Driver Store package was replaced by the newly prepared
package, the physical SC-D70 device and its audio endpoints reported
`OK`. The device continued to work after an ordinary reboot.

The final tested state was:

| Setting / Function | Result |
|---|---|
| Windows 11 x64 | ✅ Working |
| Memory Integrity | **ON** |
| Secure Boot | **OFF** |
| Windows Test Mode | **ON** |
| USB Audio (Windows/WDM) | ✅ Working |
| MIDI PART A | ✅ Working |
| MIDI PART B | ✅ Working |
| ASIO registration | ✅ Confirmed |
| ASIO host initialization | ✅ Confirmed |
| ASIO playback | ✅ Working |
| ASIO tested setting | **48 kHz / 480 samples (10 ms)** |
| Ordinary reboot persistence | ✅ Confirmed |

### Reproduction test — 2026-08-24

On 2026-08-24, the test-signing procedure was repeated from a verified
clean baseline to determine whether the previous success was reproducible
rather than dependent on the original experimental state.

Before the reproduction test, the previous SC-D70 Driver Store package,
installed driver and ASIO files, ASIO/COM registry entries, and local test
certificate were removed. Windows was rebooted with Test Signing disabled,
and the absence of these components was verified.

The reproduction then started again from the original Roland Vista x64
driver package. A **new test certificate** was created, `RDWM1012.SYS` was
test-signed again, the catalog was regenerated with `Inf2Cat` and signed
with the new certificate, and the resulting package was added to the
Driver Store. After Test Signing was enabled and Windows rebooted, connecting
the SC-D70 caused Windows to bind the device automatically to the newly
prepared package.

The reproduced installation successfully restored:

- the physical Roland SC-D70 MEDIA device (`Started`);
- Windows USB Audio, with actual playback confirmed;
- MIDI PART A and PART B, with actual playback confirmed;
- the SC-D70 ASIO registration and COM mapping; and
- actual ASIO audio playback from an ASIO-capable host.

A final ordinary reboot was performed with the SC-D70 installed. After
that reboot, **Windows audio, MIDI PART A/B, and ASIO playback all remained
functional**.

Thus, the result obtained on 2026-08-23 was independently reproduced from
a clean Windows baseline using a newly generated test certificate and
newly signed SYS/catalog files.

> **First success = discovery. Second success from a clean baseline = reproducibility.**

## Windows 11 Configuration Changes

The successful persistent configuration required changes at several levels of the Windows 11 system:

| Level | Change / State |
|---|---|
| BIOS / UEFI | **Secure Boot: OFF** |
| Windows boot configuration | **Test Signing Mode: ON** |
| Windows Security | **Memory Integrity (HVCI): ON** — no need to disable it |
| Driver trust / Driver Store | Original SC-D70 driver package **locally test-signed and replaced** |

In other words, the experiment did **not** require disabling Memory Integrity, but it did require disabling Secure Boot, enabling Windows Test Mode, and installing a locally test-signed version of the legacy driver package.

Detailed commands and the experimental sequence are preserved in the documentation under `docs/`.

## Documentation

-   [`docs/experimental-log-2026-08-23.md`](docs/experimental-log-2026-08-23.md)
    --- detailed English experimental record.
-   [`docs/experimental-log-2026-08-23-ko.md`](docs/experimental-log-2026-08-23-ko.md)
    --- detailed Korean experimental record.

The detailed logs follow the experimental sequence and preserve the
important commands, outputs, and functional observations. Where an exact
intermediate command was not preserved in the original record, it is not
presented as a verbatim log entry; reproduction notes are kept separate.

## ASIO confirmation

The Vista x64 INF explicitly includes the ASIO files:

``` text
[RDID0012.Files.Asio]
rdas1012.dll

[RDID0012.Files.As32]
rdaw1012.dll
rdah1012.dat
```

On the successfully configured Windows 11 system, the ASIO registry
entry was:

``` text
Roland SC-D70
CLSID {4C258F3C-BDB2-4183-A5B5-C2BB845B426B}
```

and that CLSID resolved to:

``` text
C:\Windows\System32\Rdas1012.dll
```

An ASIO-capable host recognized **Roland SC-D70**, initialized it at
**48,000 Hz** with a **480-sample (10.0 ms)** buffer, and produced
audible output through the SC-D70. This distinguishes the result from
merely finding a stale ASIO registry entry: the legacy ASIO driver was
actually loaded and used for audio streaming.

## What this is not

This is **not**:

-   an official Roland Windows 11 driver;
-   a Microsoft production-signed driver;
-   a newly written replacement driver; or
-   evidence that Secure Boot can remain enabled with this test-signed
    package.

The persistent experiment used:

``` text
Secure Boot: OFF
Windows Test Mode: ON
Memory Integrity: ON
```

That is not equivalent to a normal production Windows security
configuration.

## Key technical lesson

The successful package workflow is best understood as:

``` text
original RDWM1012.SYS
        ↓
add a local test signature
        ↓
generate/regenerate the catalog against that signed SYS
        ↓
test-sign the catalog
        ↓
replace the old Driver Store package
        ↓
run under Windows Test Signing
```

Signing the SYS changes the file, so a final catalog must correspond to
the signed SYS rather than an earlier copy.

A second practical lesson was that simply adding the INF did not
initially replace the package already present in the Driver Store. The
first attempt returned:

``` text
드라이버 패키지를 추가했습니다. (시스템에 이미 있음)
추가된 드라이버 패키지: 0
```

and the device still showed Code 52. After the old package was dealt
with, a later add returned:

``` text
추가된 드라이버 패키지: 1
```

and the SC-D70 physical MEDIA device became `OK`.

## Security warning

Disabling Secure Boot and enabling Windows Test Mode weakens the normal
Windows boot trust model. Microsoft documents TESTSIGNING as a
development and test configuration for loading test-signed kernel-mode
code; changes require a restart, and with Memory Integrity/HVCI enabled
the binary itself must carry a test signature. Do not treat this as a
recommended permanent configuration for a security-sensitive or
general-purpose PC without understanding the consequences.

For occasional use, a one-boot Driver Signature Enforcement bypass may
be preferable to leaving Test Mode enabled.

## Driver files and redistribution

This repository should document the method and results, not redistribute
Roland's driver binaries or modified/test-signed copies unless
redistribution rights have been established.

In particular, do not commit the original or re-signed copies of files
such as:

``` text
RDWM1012.SYS
RDID1012.CAT
Roland DLL/DAT files
Setup.exe
```

Documentation, scripts, screenshots, hashes, and legitimate source links
are appropriate repository content.

## Suggested layout

``` text
sc-d70-windows11/
├── README.md
├── docs/
│   ├── experimental-log-2026-08-23.md
│   └── experimental-log-2026-08-23-ko.md
├── scripts/
│   ├── capture-sc-d70-success-state.ps1
│   └── capture-sc-d70-build-package.ps1
└── images/
```

## Status

**Proof of concept: successful on 2026-08-23 and independently reproduced
from a clean baseline on 2026-08-24.**

A different future goal would be a properly authorized
production-signing path that permits:

``` text
Secure Boot: ON
Windows Test Mode: OFF
Memory Integrity: ON
```

That was **not** achieved in this experiment.

## Disclaimer

Use this information at your own risk. Kernel-driver installation and
firmware security changes can affect system security and boot behavior.
Results from this experiment do not guarantee compatibility with every
Windows 11 installation.

Roland and Sound Canvas are trademarks of their respective owner. This
independent project is not affiliated with or endorsed by Roland
Corporation or Microsoft.
