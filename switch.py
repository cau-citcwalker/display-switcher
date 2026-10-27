"""Send the secondary (non-primary) LG monitor to another input via DDC/CI (VCP 0x60).

  pythonw switch.py           # secondary monitor -> Linux laptop
  python  switch.py list      # show current input of every monitor
  python  switch.py 0x12      # secondary monitor -> given input code

ponytail: LG accepts 0x60 writes only from the *active* input, so this side can
only send the monitor away. The way back is `ddcutil setvcp 60 0x12` on the laptop.
"""
import ctypes
import sys
from ctypes import wintypes

# Measured on this LG (RTK scaler), not the MCCS standard table.
PC = 0x12
LAPTOP = 0x11

user32 = ctypes.windll.user32
dxva2 = ctypes.windll.dxva2


class PHYSICAL_MONITOR(ctypes.Structure):
    _fields_ = [("handle", wintypes.HANDLE), ("desc", wintypes.WCHAR * 128)]


class MONITORINFO(ctypes.Structure):
    _fields_ = [("cb", wintypes.DWORD), ("rc", wintypes.RECT),
                ("work", wintypes.RECT), ("flags", wintypes.DWORD)]


def monitors():
    """[(is_primary, PHYSICAL_MONITOR), ...]"""
    hmons = []
    cb = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMONITOR, wintypes.HDC,
                            ctypes.POINTER(wintypes.RECT), wintypes.LPARAM)
    user32.EnumDisplayMonitors(None, None, cb(lambda h, *_: hmons.append(h) or True), 0)
    out = []
    for h in hmons:
        mi = MONITORINFO(cb=ctypes.sizeof(MONITORINFO))
        user32.GetMonitorInfoW(h, ctypes.byref(mi))
        n = wintypes.DWORD()
        dxva2.GetNumberOfPhysicalMonitorsFromHMONITOR(h, ctypes.byref(n))
        arr = (PHYSICAL_MONITOR * n.value)()
        dxva2.GetPhysicalMonitorsFromHMONITOR(h, n.value, arr)
        out += [(bool(mi.flags & 1), m) for m in arr]
    return out


def get_input(m):
    cur, mx = wintypes.DWORD(), wintypes.DWORD()
    ok = dxva2.GetVCPFeatureAndVCPFeatureReply(m.handle, 0x60, None, ctypes.byref(cur), ctypes.byref(mx))
    return cur.value & 0xFF if ok else None


if __name__ == "__main__":
    mons = monitors()
    try:
        if sys.argv[1:] == ["list"]:
            for primary, m in mons:
                v = get_input(m)
                print(f"{'primary  ' if primary else 'secondary'} input={'?' if v is None else hex(v)}")
        else:
            target = int(sys.argv[1], 0) if len(sys.argv) > 1 else LAPTOP
            secondary = next(m for primary, m in mons if not primary)
            if not dxva2.SetVCPFeature(secondary.handle, 0x60, target):
                sys.exit(f"SetVCPFeature failed: {ctypes.FormatError()}")
    finally:
        for _, m in mons:
            dxva2.DestroyPhysicalMonitor(m.handle)
