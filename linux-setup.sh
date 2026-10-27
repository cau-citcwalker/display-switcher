#!/bin/sh
# Linux laptop (XFCE, Debian/Ubuntu): Ctrl+Alt+M sends the LG monitor back to the Windows PC.
# Run once: sh linux-setup.sh, then reboot.
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
# 0x12 = PC input on this LG (measured; not the MCCS standard table)
xfconf-query -c xfce4-keyboard-shortcuts -p '/commands/custom/<Primary><Alt>m' -n -t string \
  -s 'ddcutil setvcp 60 0x12 --noverify'
echo "Done. Reboot, then Ctrl+Alt+M (test: ddcutil setvcp 60 0x12)"
