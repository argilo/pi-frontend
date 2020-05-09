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
sudo raspi-config nonint do_memory_split 128
sudo raspi-config nonint do_overscan 1

sudo rm -f /etc/xdg/autostart/piwiz.desktop

if ! grep "myth31" /etc/apt/sources.list; then
    sudo sh -c "echo deb http://dl.bintray.com/bennettpeter/deb/ buster myth31 >> /etc/apt/sources.list"
    wget -O - https://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -
fi
sudo apt-get update
sudo apt-get install -y \
    ir-keytable \
    lirc \
    mythtv-light \
    || true

sudo cp /etc/lirc/lircd.conf.dist /etc/lirc/lircd.conf
sudo cp /etc/lirc/lirc_options.conf.dist /etc/lirc/lirc_options.conf
sudo apt-get install -y

if [ ! -e ~/.config/autostart/mythtv.desktop ]; then
    mkdir -p ~/.config/autostart
    cp mythtv.desktop ~/.config/autostart/
fi

if [ ! -e ~/.mythtv/lircrc ]; then
    mkdir -p ~/.mythtv
    cp lircrc ~/.mythtv/
fi

if ! grep "ir-keytable" /etc/rc.local; then
    sudo cp ir-keytable-hauppauge.cfg /etc/
    sudo sed -i -e '$iir-keytable -p rc-5,rc-6\nir-keytable --write=/etc/ir-keytable-hauppauge.cfg\n' /etc/rc.local
fi

echo "Successfully configured MythTV."
