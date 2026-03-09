# Building the EPANET User Interface
This document contains instructions for building the EPANET user interface for both Windows and Linux on the x86_64 family of CPUs. Instructions for MacOS will be added at a later date.

## Build Tools
To build the EPANET UI you need the Lazarus Integrated Development Environment (version 4.4) and the Free Pascal Compiler (version 3.2.2). If these are not already installed on your machine we recommend using [FPCUPdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases) to install the latest stable versions of them.

## Required Packages
The following packages must be installed into your Lazarus setup to build the EPANET UI. They can be installed by selecting either the **Install/Uninstall Package** command or the **Online Package Manager** command from Lazarus' **Package** menu as indicated in the table below.

| Package | Version | Install Command |
| ------ | ------ | ------ |
| TAChartBgra | 1.0 | Install/Uninstall Package |
| TAChartLazarusPkg | 1.0 | Install/Uninstall Package |
| OnlinePackageManager | 1.0.1.2 | Install/Uninstall Package |
| HtmlViewer | FrameViewer09 | Online Package Manager |
| LazMapViewer | 1.0.2.0 | Online Package Manager|

## Required Libraries
The following third-party libraries are required to build the EPANET UI:
| Name | Version | Source Code Location | Windows Name | Linux Name |
| ---- | ------- | -------------------- | ---------------- | ---------------- |
| epanet | 2.3.5 | https://github.com/openwateranalytics/epanet | epanet2.dll | libepanet2.so |
| epanet-MSX | 2.0 | https://github.com/USEPA/EPANETMSX | epanetmsx.dll | libepanetmsx.so |
| ShapeLib | 1.5.0 | http://shapelib.maptools.org | shplib.dll | libshp.so |
| Proj4 | 4.3 | https://github.com/OrdnanceSurvey/proj.4 | proj.dll | libproj.so |

Binaries for each of these libraries have been placed in the *bin* folder of this repository.

## Build Instructions
### Windows 64-bit
1. Launch Lazarus and from the **File** menu open ***epanet_ui_win64.lpi***.
2. From the **Run** menu select the **Build** command.
3. The newly created executable file ***epanet-ui.exe*** will appear in the **bin/win64** folder.

### Linux 64-bit
1. Open a terminal window and navigate to the directory where this project resides.
2. Issue the following commands to setup your Lazarus environment for building **epanet-ui**:
```
chmod +x linuxsetup.sh
sudo ./linuxsetup.sh
```
3. Launch Lazarus and from the **File** menu open ***epanet_ui_linux.lpi***.
4. From the **Run** menu select the **Build** command.
5. The newly created executable file ***epanet-ui*** will appear in the **bin/linux** folder.
6. Make **epanet-ui** executable by closing Lazarus and issuing the following commands in the terminal window:
```
cd bin/linux
chmod +x epanet-ui
```
