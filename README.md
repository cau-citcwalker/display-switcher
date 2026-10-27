# display-switcher

LG 모니터 하나를 Windows PC와 Linux 노트북이 같이 쓸 때, 입력 전환을 단축키로 하는 도구. DDC/CI(VCP `0x60`)로 모니터에 직접 명령을 보낸다.

각 머신은 모니터를 **상대 쪽으로 보내기만** 한다. 테스트한 LG 모니터는 화면에 안 보이는 쪽 머신이 보낸 전환 명령을 무시했다. 화면이 노트북에 있으면 노트북에서, PC에 있으면 PC에서 Ctrl+Alt+M.

## 입력 코드 확인

LG(RTK 스케일러) 모니터는 MCCS 표준 표와 다른 코드를 쓸 수 있다. 개발한 환경 기준: PC = `0x12`, 노트북 = `0x11`.

```sh
python switch.py list
```

다르면 `switch.py`의 `LAPTOP`을 고친다. Linux 쪽은 설치 스크립트가 직접 찾는다.

## Windows

Python 3만 필요하다 (외부 패키지 없음).

```sh
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

```sh
sh linux-setup.sh
```

모니터가 노트북 화면을 보여주는 상태에서 실행한다. `ddcutil` 설치, i2c 접근 권한 설정, NVIDIA 독점 드라이버면 DDC/CI용 옵션(`RMUseSwI2c`)까지 넣는다.

그다음 PC로 돌려보내는 후보 명령(표준 `0x60`, LG 전용 `0xF4` @ I2C `0x50`)을 하나씩 보내고 PC로 넘어갔는지 묻는다. `y`라고 답한 명령이 Ctrl+Alt+M에 걸린다. 처음 실행이면 끝나고 재부팅.
