#!/bin/bash

# Attempt at creating an AppImge for decoding OPS-SAT's beacon
#
# Build applications for receiving, demodulating, and decoding the UHF signal
# transmitted by the ESA OPS-SAT mission and a graphical application for viewing and parsing
# the beacon frames transmitted by OPS-SAT
#
# https://opssat1.esoc.esa.int/projects/amateur-radio-information-bulletin
# https://twitter.com/Magellan13016/status/1205750822069526528

#############################################################################
# Build dependencies
#############################################################################

sudo apt-get -y install libcurl-dev python3-pyqt5 python3-zmq python3-numpy
sudo pip3 install crccheck

APPDIR=$(readlink -f appdir)
mkdir -p "${APPDIR}"

#############################################################################
# 1. UHF receiver application (os_uhf_rx.grc) 
#############################################################################

# Gpredict
# also available as an AppImage: https://github.com/csete/gpredict/releases
git clone https://github.com/csete/gpredict
cd gpredict
 ./configure --prefix=/usr
make -j$(nproc)
make DESTDIR="${APPDIR}" install
cd ..

# gr-gpredict-doppler
mkdir build
cd build
cmake ../ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make DESTDIR="${APPDIR}" install
cd ../..

#############################################################################
# 2. OPS-SAT demodulator and decoder (os_demod_decode.grc)
#############################################################################

git clone https://github.com/daniestevez/gr-satellites
cd gr-satellites
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
make DESTDIR="${APPDIR}" install
sudo ldconfig
cd ../..

#############################################################################
# 3. OPS-SAT UHF Desktop (apps/desktop/main.py) 
#############################################################################

# https://pypi.org/project/PyQt5/
# https://pypi.org/project/pyzmq/
# https://pypi.org/project/crccheck/
# https://pypi.org/project/numpy/

#############################################################################
# 4. https://github.com/esa/gr-opssat
#############################################################################

# The GUI desktop application does not need to be running for the system to operate,
# i.e. the receiver application and demodulator application can operatate standalone.
# The GUI desktop is merely meant for parsing and viewing AX100 beacon contents.
# It receives the RS decoded CSP packet + 4 byte CRC32-C over a ZMQ socket
# on localhost port 38211 to which it is subscribed

# The OPS-SAT desktop application can be started with:
# python3 apps/desktop/main.py

# QUESTION: This application writes to 3 logfiles in apps/desktop/log
# which is bad, since the application does not have write rights in apps/
# it should write somewhere in $HOME instead. How to change this?

#############################################################################
# GNURadio Companion
#############################################################################

# Also need GNURadio Companion (GRC)?
# "Open the flowgraphs apps/os_uhf_rx.grc and apps/os_demod_decode.grc and run
# them from GNURadio Companion. You should now see PDU's being printed in the
# terminal of the demodulator application every 10 seconds."
# QUESTION: Can we assume that the user can utilize CRC coming with the system?
# https://wiki.gnuradio.org/index.php/GNURadioCompanion#Installing_GRC

#############################################################################
# Deploy remaining dependencies into AppDir
#############################################################################

wget -c https://github.com/$(wget -q https://github.com/probonopd/go-appimage/releases -O - | grep "appimagetool-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
chmod +x appimagetool-*.AppImage

./appimagetool-*.AppImage deploy "${APPDIR}"/usr/share/applications/*.desktop

#############################################################################
# Turn AppDir into AppImage
#############################################################################

./appimagetool-*.AppImage "${APPDIR}"
