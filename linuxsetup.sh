#!/bin/bash
echo "Setting up EPANET-UI ..."
if command -v apt &> /dev/null; then
    apt install openssl
    apt install libqt5pas-dev
elif command -v dnf &> /dev/null; then
    dnf install openssl
    dnf install qt5pas-devel
else
    echo "Setup Failed - could not identify your system's package manager."
    exit
fi
cd ./bin/linux
ln -s libproj.so libproj.so.12
cd ..
cd ..
echo "EPANET-UI setup completed."
echo
