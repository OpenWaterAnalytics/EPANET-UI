# Building EPANET-UI on macOS

These notes cover building the EPANET-UI (Lazarus) app on macOS (Apple Silicon).

## Prerequisites

You may need to do a bit of one-time setup in your Lazarus environment.

### Follow other instructions in `building.md` to get most of the required packages.
- TAChartBgra
- TAChartLazarusPkg
- OnlinePackageManager

### Install the BGRA Bitmap Pack

- Download: https://github.com/bgrabitmap/bgrabitmap/releases/tag/v11.6.6
- Unzip it
- Copy it to `lazarus/components/`
- Open the package in Lazarus and compile it

### Install HtmlViewer

- Download: https://github.com/BerndGabriel/HtmlViewer/releases/tag/11.10
- Same basic steps as above (unzip → copy into `lazarus/components/` → open package → compile)

Reason for the manual install: there’s a font-finding issue with the package-manager version.
After this is installed you can use the online package manager to install the LazMapViewer package, which depends on HtmlViewer.

### Install required system libraries

Use Homebrew to install the required `libomp`. This will be used in MSX compilation as well as the application bundling process.

Also build the required libraries (epanet, msx, shapelib, proj) from source code and place the resulting dynamic libraries in the *bin* folder of this repository.

### MSX compilation note

For MSX compilation, you may have to do something like this:

```bash
cmake -DOpenMP_C_FLAGS="-Xclang -fopenmp -I/usr/local/opt/libomp/include" \
      -DOpenMP_C_LIB_NAMES="libomp" \
      -DOpenMP_libomp_LIBRARY="omp" \
      -DEPANET_LIB=/Users/me/dev/EPANET-UI/bin/mac/libepanet2.dylib \
      ..
```

## Build the UI application bundle

1. Launch Lazarus and from the **File** menu open ***epanet_ui_mac.lpi***.
2. From the **Run** menu select the **Build** command.
3. The newly created executable file ***epanet-ui.app*** will appear in the **bin/mac** folder.
4. Finalize the application bundle. This is a rather cumbersome process that should eventually be scripted (or use a tool to convert Lazarus project to Xcode).

## Fix the UI application bundle

1. Navigate to the `Contents/MacOS` folder of the `epanet-ui.app` bundle, and place the required dynamic libraries (epanet, msx, shapelib, proj, omp) in a `Frameworks` folder that you create there.
2. Use the `otool` and `install_name_tool` commands in the terminal to update the library paths in the executable to point to the `Frameworks` folder you just created.
3. Move/copy the `epanet-ui` application binary to the `MacOS` folder of the app bundle, replacing the alias file that was there before.
4. Add a relative loader path so the binary can find its dynamic libs:

   `install_name_tool -add_rpath @loader_path/../Frameworks epanet-ui`

5. Use `otool -L epanet-ui` to verify that the library paths are correct and relative to the app bundle. You should see something like this:

```text
epanet-ui:
	<snip - system files - snip>
	@rpath/libepanet2.dylib (compatibility version 0.0.0, current version 0.0.0)
	@rpath/libepanetmsx.dylib (compatibility version 0.0.0, current version 0.0.0)
	@rpath/libshp.2.dylib (compatibility version 4.0.0, current version 4.0.0)
	@rpath/libproj.10.dylib (compatibility version 11.0.0, current version 11.0.0)
	<snip - system files - snip>
```

## Sign and notarize the app bundle

```bash
codesign --force --deep --options runtime --timestamp --sign "<Your-Developer-ID>" epanet-ui.app
codesign --verify --verbose=4 epanet-ui.app
spctl --assess --verbose "epanet-ui.app"
/usr/bin/ditto -c -k --keepParent "epanet-ui.app" "epanet-ui.zip"
xcrun notarytool submit "epanet-ui.zip" --keychain-profile "YourNotaryProfile" --wait
xcrun stapler staple "epanet-ui.app"
```
