#!/usr/bin/env bash

# This file is part of pi-frontend.
#
# pi-frontend is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pi-frontend is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with pi-frontend.  If not, see <https://www.gnu.org/licenses/>.

set -e

sudo raspi-config nonint do_blanking 1
sudo raspi-config nonint do_change_locale en_US.UTF-8
sudo raspi-config nonint do_change_timezone "America/Toronto"
sudo raspi-config nonint do_configure_keyboard us
sudo raspi-config nonint do_overscan 1
sudo raspi-config nonint do_boot_behaviour B4
sudo raspi-config nonint do_hostname argilo-frontend

sudo rm -f /etc/xdg/autostart/piwiz.desktop

sudo apt-get update
sudo apt-get install -y \
    gdebi-core \
    ir-keytable \
    lirc \
    || true

if ! command -v mythfrontend &> /dev/null; then
    wget http://argilo-backend.local/mythtv/20231014-mythtv-light_33.1-22-g26e76a3949-0_arm64_bookworm.deb
    sudo gdebi -n 20231014-mythtv-light_33.1-22-g26e76a3949-0_arm64_bookworm.deb
fi

if [ ! -e ~/.config/autostart/mythtv.desktop ]; then
    mkdir -p ~/.config/autostart
    cp mythtv.desktop ~/.config/autostart/
fi

if ! grep "event4" /etc/lirc/lirc_options.conf; then
    sudo sed -i -e 's/auto/\/dev\/input\/event4/' /etc/lirc/lirc_options.conf
fi

if [ ! -e ~/.mythtv/lircrc ]; then
    mkdir -p ~/.mythtv
    cp lircrc ~/.mythtv/
fi

if [ ! -e /etc/rc_keymaps/ir-keytable-hauppauge.toml ]; then
    sudo cp ir-keytable-hauppauge.toml /etc/rc_keymaps/
fi

if ! grep ir-keytable-hauppauge /etc/rc_maps.cfg; then
    sudo sh -c "echo 'mceusb  *                        /etc/rc_keymaps/ir-keytable-hauppauge.toml' >> /etc/rc_maps.cfg"
fi

if ! grep "scaling_governor" /etc/rc.local; then
    sudo sed -i -e '$iecho performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\n' /etc/rc.local
    sudo systemctl disable raspi-config
fi

sudo systemctl disable cups
sudo systemctl disable cups-browsed
sudo systemctl disable ModemManager.service

if ! grep "vm.swappiness=5" /etc/sysctl.conf; then
    sudo sh -c "echo vm.swappiness=5 >> /etc/sysctl.conf"
fi

echo "Successfully configured MythTV."
