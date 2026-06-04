#!/bin/bash

echo "Setting up EPANET-UI ..."

echo "Checking for package manager and installing dependencies ..."
if command -v apt &> /dev/null; then
    echo "Using apt — installing openssl and libqt5pas-dev ..."
    apt update
    apt install -y openssl libqt5pas-dev

elif command -v dnf &> /dev/null; then
    echo "Using dnf — installing openssl and qt5pas-devel ..."
    dnf install -y openssl qt5pas-devel

else
    echo "Setup Failed - could not identify your system's package manager."
    exit 1
fi

echo "Changing directory to ./bin/linux ..."
cd ./bin/linux || {
    echo "Missing ./bin/linux directory — cannot continue."
    exit 1
}

echo "Creating symlink libproj.so.12 → libproj.so (if missing) ..."
[ -e libproj.so.12 ] || ln -s libproj.so libproj.so.12

echo "Checking for epanet-ui binary ..."
if [ -f "./epanet-ui" ]; then
    echo "Binary found — making it executable ..."
    chmod +x epanet-ui
    
    cd ../..
    
    echo "EPANET-UI setup completed."
else
    echo "You need the compiled binary to finish the setup!"
    echo "Alternatively you can download it from https://sites.google.com/view/epanet-ui"
fi

echo
