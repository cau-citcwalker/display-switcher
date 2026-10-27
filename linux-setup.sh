#!/bin/sh
# Linux laptop (XFCE, Debian/Ubuntu): Ctrl+Alt+M sends the LG monitor back to the Windows PC.
# Run with the monitor showing this laptop: sh linux-setup.sh, then reboot.
set -e
sudo apt install -y ddcutil
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
sudo modprobe i2c-dev
# NVIDIA proprietary driver: DDC/CI fails without software I2C (ddcutil docs, "nvidia")
if lsmod | grep -q '^nvidia '; then
  echo 'options nvidia NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100' | sudo tee /etc/modprobe.d/nvidia-i2c.conf
  sudo update-initramfs -u
fi
sudo groupadd -f i2c
echo 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"' | sudo tee /etc/udev/rules.d/45-i2c.rules
sudo udevadm control --reload && sudo udevadm trigger
sudo usermod -aG i2c "$USER"

# Find the command that brings the monitor back to the PC. LG often ignores 0x60 in one
# direction; many LG models need vendor feature 0xF4 at I2C source address 0x50 instead.
echo "Monitor must be showing this laptop now. Sending candidates one by one."
for cmd in 'setvcp 60 0x12' '--i2c-source-addr=x50 setvcp 0xf4 0x90' \
           '--i2c-source-addr=x50 setvcp 0xf4 0x91' 'setvcp 60 0x10'; do
  echo ">>> ddcutil --noverify $cmd"
  sudo ddcutil --noverify $cmd || true
  printf 'Monitor switched to the PC? [y/N] '; read ok
  if [ "$ok" = y ]; then
    xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Primary><Alt>m' -n -t string \
      -s "ddcutil --noverify $cmd"
    echo "Ctrl+Alt+M = ddcutil --noverify $cmd. Reboot if this is the first run."
    exit 0
  fi
done
echo "Nothing worked. If this is the first run, reboot and run again; otherwise send the output above."
