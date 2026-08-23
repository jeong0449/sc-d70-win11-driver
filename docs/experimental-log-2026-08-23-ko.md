# Roland SC-D70 on Windows 11 --- 실험 기록

**실험일:** 2026-08-23\
**장치:** Roland SC-D70\
**원본 드라이버:** Windows Vista 64비트용 Roland SC-D70 driver, version
1.0.0.0, 2007-01-22\
**호스트:** Windows 11 x64\
**문서 성격:** 2026-08-23 ChatGPT 대화에 남은 사용자 입력과 출력에
근거하여 정리한 실험 기록

> 이 판은 이전 문서와 달리, "재현하기 좋은 성공 절차"와 "대화에서 실제로
> 확인된 실험 기록"을 구분한다. 사용자가 명령과 출력을 직접 붙여 넣은
> 경우에는 **\[확인: 명령+출력\]**, 결과만 말로 확인한 경우에는
> **\[확인: 결과\]**, 대화 중 제안되었으나 사용자 실행 로그가 현재
> 기록에서 확인되지 않는 명령은 **\[재현용/실행로그 미확인\]**으로
> 표시한다. 기술적 설명은 **\[해석\]**으로 구분한다.

## 1. 이번 실험의 두 줄기

첫 번째 실험은 2007년 Vista 64비트 드라이버가 Windows 11에서도 실제로
동작하는지를 확인하는 것이었다. 원본 패키지는 Driver Store에 들어갔지만
정상 상태로 로드되지 않았고, 상세 조회에서 Code 39를 거쳐 Code 52가
확인되었다. 이후 Windows의 Driver Signature Enforcement를 한 번의 부팅에
한하여 해제한 상태에서 SC-D70이 정상 장치로 나타났으며, MIDI PART A/B와
USB Audio가 실제로 동작했다.

두 번째 실험은 이 드라이버를 현대적인 test-signing 방식으로 다시
패키징하여, 매번 F7 부팅을 하지 않고 평범하게 재부팅해도 사용할 수
있는지를 확인하는 것이었다. 최신 WDK의 Inf2Cat과 SignTool을 사용했고,
자체 테스트 인증서로 SYS/CAT을 서명했다. 최종적으로 Secure Boot OFF,
Test Mode ON 상태에서 정상 재부팅 후에도 SC-D70이 작동했다. Memory
Integrity는 ON 상태였다.

이 두 번째 작업은 새로운 기능 드라이버를 개발한 것이 아니다. 대화에서
확인된 범위에서 `RDWM1012.SYS`의 기능 코드를 수정했다는 기록은 없으며,
기존 바이너리에 test signature를 부여하고 catalog를 다시 구성한
실험이다.

------------------------------------------------------------------------

# Part I --- 원본 Vista 64비트 드라이버

## 2. 원본 INF 설치

### 2.1 일반 권한에서 첫 시도

**\[확인: 명령+출력\]**

사용자가 실행한 명령:

``` powershell
pnputil /add-driver RDIF1012.INF /install
```

출력:

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가하지 못함: 액세스가 거부되었습니다.

총 드라이버 패키지:  1
추가된 드라이버 패키지:  0
```

**\[해석\]** 이 단계의 실패 원인은 드라이버 자체가 아니라 권한이었다.

### 2.2 관리자 모드에서 재실행

**\[확인: 명령+출력\]**

``` powershell
pnputil /add-driver RDIF1012.INF /install
```

출력:

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다.
게시된 이름:         oem76.inf
드라이버 패키지가 장치에 설치됨: USB\VID_0582&PID_000C\6&197fd1e3&0&4

총 드라이버 패키지:  1
추가된 드라이버 패키지:  1
```

여기서 `oem76.inf`는 이 PC에서 당시 부여된 게시 이름이다. 다른 PC에서
같은 번호가 사용된다는 뜻은 아니다.

## 3. PnP 상태 확인

**\[확인: 명령+출력\]**

``` powershell
Get-PnpDevice | Where-Object {
    $_.FriendlyName -match "SC-D70|Roland"
} | Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
```

출력:

``` text
Status Class FriendlyName  InstanceId
------ ----- ------------  ----------
Error  MEDIA Roland SC-D70 USB\VID_0582&PID_000C\6&197FD1E3&0&4
```

### 3.1 Code 39

**\[확인: 출력\]**

상세 장치 조회에서 한 시점에 다음 상태가 기록되었다.

``` text
인스턴스 ID:                USB\VID_0582&PID_000C\6&197fd1e3&0&4
장치 설명:                  Roland SC-D70
클래스 이름:                MEDIA
클래스 GUID:                {4d36e96c-e325-11ce-bfc1-08002be10318}
제조업체 이름:              Roland
상태:                       문제
문제 코드:                  39 (0x27) [CM_PROB_DRIVER_FAILED_LOAD]
문제 상태:                  0xC000007B
드라이버 이름:              oem76.inf
서비스:                     RDID1012
```

### 3.2 Code 52

**\[확인: 명령+출력\]**

``` powershell
pnputil /enum-devices /instanceid "USB\VID_0582&PID_000C\6&197fd1e3&0&4" /drivers /services
```

핵심 출력:

``` text
인스턴스 ID:                USB\VID_0582&PID_000C\6&197fd1e3&0&4
장치 설명:                  Roland SC-D70
클래스 이름:                MEDIA
클래스 GUID:                {4d36e96c-e325-11ce-bfc1-08002be10318}
제조업체 이름:              Roland
상태:                       문제
문제 코드:                  52 (0x34) [CM_PROB_UNSIGNED_DRIVER]
문제 상태:                  0xC0000428
드라이버 이름:              oem76.inf
서비스:                     RDID1012
일치하는 드라이버:
    드라이버 이름:          oem76.inf
    원래 이름:              rdif1012.inf
    공급자 이름:            Roland
    클래스 이름:            MEDIA
    클래스 GUID:            {4d36e96c-e325-11ce-bfc1-08002be10318}
    드라이버 버전:          01/22/2007 1.0.0.0
    서명자 이름:            Roland Corporation
    일치하는 장치 ID:       USB\VID_0582&PID_000C
    드라이버 순위:          00FF0001
    드라이버 상태:          최고 순위 / 설치됨
```

**\[해석\]** 패키지는 설치되었지만 장치가 정상적으로 로드되지 않았고,
Code 52는 서명 검증이 핵심 장애물임을 직접 보여 주었다.

## 4. Driver Signature Enforcement 일시 해제 후

Windows Advanced Startup의 Startup Settings에서 Driver Signature
Enforcement를 한 번의 부팅에 한하여 해제하는 절차를 사용했다.

**\[확인: 결과\]** 대화에는 이 부팅 메뉴에서 실제로 누른 키 입력 전체가
셸 로그 형태로 남아 있지는 않지만, 이후 사용자가 다음 정상 장치 출력을
직접 제시했다.

``` text
Status Class         FriendlyName       InstanceId
------ -----         ------------       ----------
OK     AudioEndpoint IN(Roland SC-D70)  SWD\MMDEVAPI\{0.0.1.00000000}.{0B4090B6-BB9B-4CD7-97F8-A6FEB2A7A2C2}
OK     MEDIA         Roland SC-D70      USB\VID_0582&PID_000C\6&197FD1E3&0&4
OK     AudioEndpoint OUT(Roland SC-D70) SWD\MMDEVAPI\{0.0.0.00000000}.{A1121493-42C1-4EA3-9A25-D74FD569056F}
```

**\[확인: 결과\]** 이어서 사용자는 "A와 B 포트 모두 작동합니다",
"윈도우즈 사운드에서 SC-D70이 잘 보이고 소리도 잘 나요"라고 실제 기능을
확인했다.

## 5. Memory Integrity를 다시 ON으로 한 뒤

**\[확인: 결과\]** 사용자는 Memory Integrity를 ON으로 하고 재부팅한 뒤
다음과 같은 장치 상태를 보고했다.

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

그리고 "아무런 오류 없고, USB audio 잘 되며, MIDI 포트도 A/B 전부
보입니다!"라고 확인했다.

**Part I 결론:** Windows 11이 로드를 허용하는 조건에서는 2007년 Vista
64비트 드라이버로 SC-D70의 USB Audio와 MIDI PART A/B가 실제로 동작했다.
Memory Integrity를 계속 OFF로 둘 필요는 없었다.

------------------------------------------------------------------------

# Part II --- Test-signing

## 6. WDK 도구 확인

### 6.1 처음의 `where.exe`

**\[확인: 명령+출력\]**

``` powershell
where.exe signtool.exe
where.exe inf2cat.exe
where.exe makecert.exe
Confirm-SecureBootUEFI
bcdedit /enum | findstr /i "testsigning"
```

기록된 출력:

``` text
where.exe signtool.exe
정보: 제공된 패턴에 해당되는 파일을 찾지 못했습니다.

where.exe inf2cat.exe
정보: 제공된 패턴에 해당되는 파일을 찾지 못했습니다.

where.exe makecert.exe
정보: 제공된 패턴에 해당되는 파일을 찾지 못했습니다.

Confirm-SecureBootUEFI
True
```

`bcdedit ... testsigning`에는 당시 출력이 없었다.

### 6.2 SignTool 발견

**\[확인: 명령+출력\]**

``` powershell
Get-ChildItem "C:\Program Files (x86)\Windows Kits\10" `
    -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
    Select-Object FullName
```

출력에는 다음 경로들이 포함되었다.

``` text
C:\Program Files (x86)\Windows Kits\10\App Certification Kit\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\arm\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\arm64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\arm64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x86\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\arm64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\signtool.exe
```

같은 방식의 Inf2Cat 검색에서는 처음 출력이 없었다. WDK 설치 후 사용자가
다음 경로를 확인했다.

``` text
C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe
```

## 7. 작업 디렉터리

**\[확인: 명령+출력\]**

작업 위치:

``` text
C:\projects\SC-D70_Win11-TestSigned
```

사용자가 `dir`로 제시한 내용:

``` text
RD3T1012.DAT       4088
RDAH1012.DAT     275968
RDAS1012.DLL     114688
RDAW1012.DLL     102400
RDCI1012.DLL      17920
RDCP1012.CPL      58880
RDDP1012.DAT     379392
RdDrvInf.dat          47
RDID1012.CAT       9953
RDIF1012.INF      13470
RdUninst.dat       1501
RDWM1012.SYS     193664
Readme_E.htm         549
Readme_J.htm         514
Setup.exe        1532728
Uninstal.exe      398136
```


## 8. Inf2Cat 성공

**\[확인: 명령+출력\]**

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x86\Inf2Cat.exe" `
  /driver:"C:\projects\SC-D70_Win11-TestSigned" `
  /os:10_X64
```

실제 출력:

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

이 단계는 대화 로그에서 명령과 결과가 모두 직접 확인된다.

## 9. 테스트 인증서

**\[확인: 결과\]** 사용자는 다음 명령의 결과를 직접 제시했다.

``` powershell
$cert | Format-List Subject,Thumbprint,NotBefore,NotAfter,HasPrivateKey
```

출력:

``` text
Subject       : CN=SC-D70 Win11 Test Driver
Thumbprint    : 18D9858E2CE72AD68A380F3ADBB2B79D6681671B
NotBefore     : 2026-08-23 오후 7:07:23
NotAfter      : 2027-08-23 오후 7:27:23
HasPrivateKey : True
```

**\[재현용/실행로그 미확인\]** 이전 문서에 적었던
`New-SelfSignedCertificate`, `Export-Certificate`,
`Import-Certificate`의 정확한 명령문은 성공 절차를 설명하기 위해
재구성한 것이다. 현재 보이는 사용자 로그에는 그 전체 명령과 출력이 직접
제시되어 있지 않다. 따라서 이 문서에서는 그것을 "실제 transcript"로
인용하지 않는다. 다만 위 출력으로 보아 해당 이름의 private key를 가진
인증서가 실제 생성되었다는 결과는 확인된다.

## 10. 원본 SYS의 서명 상태

**\[확인: 명령+출력\]**

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" `
  verify /v /kp .\RDWM1012.SYS
```

첫 확인 결과:

``` text
Verifying: .\RDWM1012.SYS
SignTool Error: No signature found.

Number of files successfully Verified: 0
Number of warnings: 0
Number of errors: 1
```

따라서 이 시점의 `RDWM1012.SYS`에는 SignTool이 확인하는 embedded
signature가 없었다.

## 11. SYS에 test signature를 추가한 뒤

**\[확인: 결과\]** 이후 같은 verify 명령의 출력이 다음과 같이 바뀌었다.

``` text
Verifying: .\RDWM1012.SYS

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

Number of files successfully Verified: 0
Number of warnings: 0
Number of errors: 1
```

**\[해석\]** `No signature found` 상태에서 `Signature Index: 0`가 보이는
상태로 바뀌었으므로 SYS에 test signature가 추가된 것은 확인된다. 다만
현재 보이는 사용자 transcript에는 SYS를 실제로 서명한
`signtool sign ...` 명령 전체가 직접 남아 있지 않으므로 그 명령문을 실제
입력으로 단정하지 않는다.

## 12. CAT 서명 확인

**\[확인: 명령+출력\]**

사용자가 다음 검증 명령을 제시했다.

``` powershell
& "C:\Program Files (x86)\Windows Kits\10\bin\10.0.28000.0\x64\signtool.exe" `
  verify /v .\RDID1012.CAT
```

출력:

``` text
Verifying: .\rdid1012.cat

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

그 뒤 사용자는 "네 지금 두 명령어에서는 에러의 수 0입니다"라고 보고했다.

**\[확인: 결과\]** 즉 후속 검증에서 SYS와 CAT 모두 error 0이 된 사실은
확인된다.

**\[재현용/실행로그 미확인\]** 이전 판에서 이를 `/pa` 검증의 전체
명령으로 복원해 놓았지만, 현재 보이는 사용자 transcript에는 그 두 명령의
전문이 직접 포함되어 있지 않다. 따라서 여기서는 "두 검증 명령에서 error
0"이라는 사용자 확인까지만 실험 사실로 기록한다.

## 13. SYS → CAT 순서

**\[해석\]** SYS에 embedded signature를 추가하면 SYS 파일 자체가
변하므로 catalog에 기록되는 해시도 달라진다. 따라서 최종 패키징 순서는
논리적으로 다음과 같아야 한다.

``` text
SYS에 test signature 추가
        ↓
그 상태의 패키지로 CAT 생성/재생성
        ↓
CAT에 test signature 추가
```

이 순서는 성공한 패키지를 이해하고 재현하는 데 중요하지만, 이전 판처럼
`Remove-Item .\RDID1012.CAT` 등 모든 중간 명령을 "사용자가 실제로 입력한
transcript"로 제시해서는 안 된다. 대화에서 직접 확인된 것은 Inf2Cat
성공, 서명 전후 SYS 검증 결과, CAT 서명 검증 결과, 그리고 최종 성공이다.

## 14. BitLocker 상태

**\[확인: 명령+출력\]**

``` powershell
manage-bde -status C:
```

출력:

``` text
C: 볼륨 [Windows]
[OS 볼륨]

    크기:                 475.69GB
    BitLocker 버전:       없음
    변환 상태:            완전 암호 해독됨
    암호화된 비율:        0.0%
    암호화 방법:          없음
    보호 상태:            보호 해제
    잠금 상태:            잠금 해제됨
    ID 필드:              없음
    키 보호기:            없음
```

이 PC의 C:에는 BitLocker가 설정되어 있지 않았다.

## 15. Secure Boot

**\[확인: 명령+출력\]**

실험 전:

``` powershell
Confirm-SecureBootUEFI
```

결과:

``` text
True
```

UEFI 진입을 위해 일반 권한에서:

``` powershell
shutdown /r /fw /t 0
```

을 실행했을 때:

``` text
클라이언트가 필요한 권한을 가지고 있지 않습니다.(1314)
```

가 나타났다.

**\[확인: 결과\]** 이후 UEFI에서 Secure Boot를 OFF로 바꾼 뒤 사용자는
`False`가 보인다고 확인했다.

> 관리자 권한에서 `/fw` 명령을 다시 실행했다는 문장은 이전 판에
> 있었지만, 현재 보이는 사용자 transcript에는 그 재실행 명령/출력이 직접
> 남아 있지 않다. 확실한 사실은 최종적으로 Secure Boot가 `False`가
> 되었다는 것이다.

## 16. Test Mode

**\[확인: 결과\]** 사용자는 이후 Test Mode가 예상대로 나타났고, 마지막
성공 뒤에도 "Test 모드로 표시되는 이유"를 질문했다. 따라서 최종 실험이
Windows Test Mode에서 이루어졌다는 사실은 확인된다.

**\[재현용/실행로그 미확인\]** `bcdedit /set testsigning on`,
`shutdown /r /t 0`, `bcdedit /enum | findstr /i "testsigning"`은 성공
절차에 해당하지만, 현재 보이는 사용자 메시지에는 이 단계의 명령과 출력
전문이 직접 남아 있지 않다. 이전 판처럼 이들을 모두 실제 입력 로그로
표시하지 않는다.

## 17. 첫 test-signed 패키지 설치 시도: 기존 패키지가 남아 있었음

**\[확인: 명령+출력\]**

``` powershell
pnputil /add-driver .\RDIF1012.INF /install
```

출력:

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다. (시스템에 이미 있음)
게시된 이름:         oem76.inf
드라이버 패키지가 장치에서 최신 상태임:USB\VID_0582&PID_000C\6&197fd1e3&0&4

총 드라이버 패키지:  1
추가된 드라이버 패키지:  0
```

이어진 상세 조회:

``` text
상태:                     문제
문제 코드:               52 (0x34) [CM_PROB_UNSIGNED_DRIVER]
문제 상태:               0xC0000428
드라이버 이름:            oem76.inf
서비스:                   RDID1012
...
서명자 이름:              Roland Corporation
```

그리고 PnP 요약:

``` text
Unknown MidiEndpoint   Roland SC-D70
Unknown SoftwareDevice Roland SC-D70
Unknown SoftwareDevice Roland SC-D70 MIDI IN
Unknown SoftwareDevice Roland SC-D70 PART A
Unknown SoftwareDevice Roland SC-D70 PART B
Unknown SoftwareDevice Roland SC-D70 MIDI OUT
Unknown AudioEndpoint  IN(Roland SC-D70)
Error   MEDIA          Roland SC-D70
Unknown AudioEndpoint  OUT(Roland SC-D70)
```

**\[해석\]** 새로 준비한 파일이 실제 장치에 적용되지 않았고 Driver
Store의 기존 Roland 패키지가 계속 사용되고 있었다.

## 18. 기존 패키지 제거 뒤 새 패키지 추가

**\[확인: 결과\]** 대화 흐름상 기존 Driver Store 패키지를 제거하는
단계가 있었고, 그 뒤 사용자가 다음 명령과 성공 출력을 직접 제시했다.

``` powershell
pnputil /add-driver .\RDIF1012.INF
```

출력:

``` text
Microsoft PnP 유틸리티

드라이버 패키지를 추가하는 중:  RDIF1012.INF
드라이버 패키지를 추가했습니다.
게시된 이름:         oem76.inf

총 드라이버 패키지:  1
추가된 드라이버 패키지:  1
```

**\[재현용/실행로그 미확인\]** 이전 판에는 다음 삭제 명령을 실제
입력처럼 적었다.

``` powershell
pnputil /delete-driver oem76.inf /uninstall /force
```

이 명령은 성공 절차상 타당하고 대화 중 제안된 단계였지만, 현재 보이는
사용자 transcript에는 사용자가 이 명령과 출력을 직접 붙여 넣은 부분이
없다. 따라서 본 점검판에서는 "기존 패키지를 제거한 뒤 새 패키지가
추가되었다"는 흐름과 새 패키지 추가 성공 로그만 확정한다.

## 19. 새 패키지 적용 후 최종 상태

**\[확인: 명령+출력\]**

``` powershell
Get-PnpDevice |
  Where-Object {$_.FriendlyName -match "SC-D70|Roland"} |
  Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
```

출력:

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

**\[확인: 결과\]** 사용자는 "네 정상 작동합니다. 재부팅해 보죠!"라고
확인했다.

## 20. 정상 재부팅 후

**\[확인: 결과\]** 재부팅 후 사용자는 "돌겠네. 완벽하게 된다는
거죠!!"라고 보고했다. 이어서 Test Mode 표시의 이유를 질문했다. 따라서
다음은 대화에서 확인된 최종 결과이다.

``` text
일반적인 재부팅: 성공
SC-D70: 정상 동작
USB Audio: 정상
MIDI PART A/B: 정상
Memory Integrity: ON
Secure Boot: OFF
Windows Test Mode: ON
```

정상 재부팅에 실제로 사용한 명령이 `shutdown /r /t 0`이었는지, GUI의
재시작이었는지는 현재 보이는 사용자 transcript만으로 확정하지 않는다.

------------------------------------------------------------------------

# 21. 재현을 위한 기술적 요약

실험 결과로부터 도출되는 재현 순서는 다음과 같다. 이 절은 transcript가
아니라 **재현 가이드**이다.

``` text
원본 Vista 64비트 driver package
        ↓
test code-signing certificate 준비
        ↓
RDWM1012.SYS test-sign
        ↓
서명된 SYS를 기준으로 catalog 생성/재생성
        ↓
catalog test-sign
        ↓
Secure Boot OFF
        ↓
Windows Test Signing ON
        ↓
기존 SC-D70 Driver Store package 제거
        ↓
test-signed package 추가
        ↓
SC-D70 연결 및 기능 확인
        ↓
일반 재부팅 후 재확인
```

`oem76.inf`와 인증서 thumbprint는 이 PC의 2026-08-23 실험에만 해당한다.
다른 PC에서 그대로 사용하면 안 된다.

------------------------------------------------------------------------

# 22. 보안 및 배포 주의

최종 지속 사용 실험은 Secure Boot를 OFF로 하고 Windows Test Mode를
사용하는 구성이다. Memory Integrity는 ON이었지만 이것이 일반적인
production Windows 11 보안 상태와 동일하다는 뜻은 아니다.

또한 Roland의 원본 SYS/DLL/DAT 및 그것을 수정·재서명한 바이너리의 공개
재배포 문제는 기술적 재현과 별개의 문제이다. 공개 저장소에는 이 실험
기록과 명령, 스크린샷 등만 두고 Roland 바이너리 자체는 넣지 않는 편이
안전하다.

------------------------------------------------------------------------

# 23. 결론

2026-08-23의 실험에서 확인한 핵심은 간단하다. 2007년 Vista 64비트용
SC-D70 드라이버는 Windows 11에서 기능적으로 여전히 동작했다. 첫
실험에서는 Driver Signature Enforcement를 일시 해제하여 이를 확인했고,
두 번째 실험에서는 현대 WDK 도구와 test-signing을 이용하여 평범한 재부팅
뒤에도 계속 사용할 수 있는 상태까지 갔다.

다만 두 번째 성공은 정식 Windows 11 production driver를 만든 것이
아니다. 최종 환경은 Secure Boot OFF와 Test Mode ON을 요구했다. 따라서
이번 결과의 가장 정확한 표현은 **"원본 SC-D70 Vista 64비트 드라이버의
Windows 11 동작을 확인하고, 재현 가능한 test-signed compatibility
configuration을 구현했다"** 정도이다.
