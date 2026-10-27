# display-switcher

LG 모니터 하나를 Windows PC와 Linux 노트북이 같이 쓸 때, 입력 전환을 단축키로 하는 도구. DDC/CI(VCP `0x60`)로 모니터에 직접 명령을 보낸다.

각 머신은 모니터를 **상대 쪽으로 보내기만** 한다. LG 모니터는 현재 보여주는 입력에서 온 전환 명령만 받기 때문이다. 화면이 노트북에 있으면 노트북에서, PC에 있으면 PC에서 Ctrl+Alt+M.

## 입력 코드 확인

LG(RTK 스케일러) 모니터는 MCCS 표준 표와 다른 코드를 쓸 수 있다. 개발한 환경 기준: PC = `0x12`, 노트북 = `0x11`.

```
python switch.py list
```

다르면 `switch.py`의 `LAPTOP`, `linux-setup.sh`의 `0x12`를 고친다.

## Windows

Python 3만 필요하다 (외부 패키지 없음).

```
python switch.py          # 보조(주 모니터 아닌) 모니터 -> 노트북
python switch.py 0x0f     # 보조 모니터 -> 지정한 입력 코드
```

Ctrl+Alt+M 단축키 등록 (저장소 폴더에서 PowerShell 실행):

```powershell
$s = (New-Object -ComObject WScript.Shell).CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Monitor to Laptop.lnk")
$s.TargetPath = (Get-Command pythonw).Source
$s.Arguments = "`"$PWD\switch.py`""
$s.Hotkey = "CTRL+ALT+M"
$s.Save()
```

## Linux (XFCE, Debian/Ubuntu)

```
sh linux-setup.sh
```

`ddcutil` 설치, i2c 접근 권한 설정, XFCE에 Ctrl+Alt+M 바인딩까지 한다. NVIDIA 독점 드라이버가 로드돼 있으면 DDC/CI용 드라이버 옵션(`RMUseSwI2c`)도 넣는다. 끝나면 재부팅.
