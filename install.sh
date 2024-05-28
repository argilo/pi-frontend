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

MYTHTV_BRANCH=fixes/34

sudo raspi-config nonint do_blanking 1
sudo raspi-config nonint do_change_locale en_US.UTF-8
sudo raspi-config nonint do_change_timezone "America/Toronto"
sudo raspi-config nonint do_configure_keyboard us
sudo raspi-config nonint do_overscan 1
sudo raspi-config nonint do_boot_behaviour B4
sudo raspi-config nonint do_hostname argilo-frontend

sudo apt-get update
sudo apt-get install -y \
    ir-keytable \
    lirc \
    || true

if [ ! -f /usr/bin/mythfrontend ]; then
    mkdir -p ~/build
    git clone --branch "${MYTHTV_BRANCH}" https://github.com/MythTV/packaging.git ~/build/packaging
    cd ~/build/packaging/deb
    ./build-debs.sh "${MYTHTV_BRANCH}"
    dpkg-scanpackages -m . > Packages
    echo "deb [trusted=yes] file://${HOME}/build/packaging/deb ./" | sudo tee /etc/apt/sources.list.d/mythtv.list
    sudo apt-get update
    sudo apt-get install -y mythtv-frontend
    sudo usermod -a -G mythtv "${USER}"
    cd -
fi

mkdir -p ~/.config/autostart
ln -s /usr/share/applications/mythtv.desktop ~/.config/autostart/mythtv.desktop

sudo cp 90-hauppauge-remote.rules /etc/udev/rules.d/

if ! grep "hauppauge_remote" /etc/lirc/lirc_options.conf; then
    sudo sed -i -e 's/auto/\/dev\/hauppauge_remote/' /etc/lirc/lirc_options.conf
fi

mkdir -p ~/.mythtv
cp lircrc ~/.mythtv/

sudo cp ir-keytable-hauppauge.toml /etc/rc_keymaps/

if ! grep ir-keytable-hauppauge /etc/rc_maps.cfg; then
    sudo sh -c "echo 'mceusb  *                        /etc/rc_keymaps/ir-keytable-hauppauge.toml' >> /etc/rc_maps.cfg"
fi

echo "Successfully configured MythTV."
