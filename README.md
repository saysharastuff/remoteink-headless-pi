# PocketBook RemoteInk Headless Xorg Setup

This project configures a Raspberry Pi (or other Linux system) to use a rooted PocketBook e-ink reader as its primary or secondary display via [RemoteInk](https://github.com/blawar/remoteink).  
It includes an install/uninstall script, an Xorg dummy display config, and a session launcher script.

This has only been tested on a PB741 (Inkpad Color) 

## Requirements

- **PocketBook with USBNet support** (See: [MobileRead](https://www.mobileread.com/forums/showthread.php?p=3921722) for more information.
- **RemoteInk** app installed on the PocketBook (from the [RemoteInk GitHub project](https://github.com/blawar/remoteink)).
- A Linux host (tested on Raspberry Pi running Ubuntu 24.04).
- USB cable for direct PocketBook ↔ Pi connection.
- Mouse/keyboard connected to the Pi for interactive use.

## PocketBook USBNet Setup

1. On the PocketBook, enable **USBNet** in **Rooted device settings**.
   - If prompted “Charge / PC Link” after plugging in, choose Charge. 
2. Connect the PocketBook to the Pi via USB.
3. On the Pi, verify a new interface appears (often `usb0` or `enx…`):
   ```bash
   ip addr show
   ```
4. Test connectivity with IP of new interface:
   ```bash
   ping 169.254.0.1
   ```

## Installation

1. Clone this repository onto your Pi:
   ```bash
   git clone https://github.com/yourname/pb-remoteink.git
   cd pb-remoteink
   ```
2. Run the install script:
   ```bash
   sudo ./install.sh
   ```
3. Follow the instructions on [RemoteInk GitHub project](https://github.com/blawar/remoteink)) to install the RemoteInk server. 
4. To ensure the cursor will display on the screen, in config.ini of the RemoteInk server config, set:
   ```
   CursorCapturingEnabled = True
   ```

4. Set your RemoteInk server password:
   ```bash
   sudo /usr/local/bin/remoteinkd passwd
   ```
4. On the PocketBook, open RemoteInk and set:
   - **Server**: `<IP of USB interface>`
   - **Port**: `9312`

## Uninstallation

```bash
sudo ./uninstall.sh
```

## Files in This Repo

- `pb-xorg-session.sh` — launches headless Xorg with dummy driver, LXDE, and RemoteInk daemon.
- `20-pb-dummy.conf` — Xorg dummy video driver config tuned for the PocketBook screen.
- `.Xresources` — sets a large, high-contrast cursor theme and size.
- `install.sh` / `uninstall.sh` — install or remove all components.
- `README.md` — this document.

## Notes

- `pb-remoteink.service` is enabled at install and will start the headless Xorg + RemoteInk session on boot.
- Tested with PocketBook InkPad Color (PB741)
- For troubleshooting, check logs in:
  - `/var/log/pb-remoteink.log`
  - `/var/log/Xorg-pb.log`
  - `/var/log/lxde.log`