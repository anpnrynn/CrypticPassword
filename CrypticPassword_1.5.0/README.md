# CrypticPassword Native Desktop GUI Project

This package reimplements `CrypticPassword.html` as desktop applications while preserving the same Generation Two seed string, shuffle algorithm, and three 6x6 matrices.

## What was preserved from the HTML

- Seed/initdata string length: 108 characters.
- Matrix layout: 3 matrices x 36 cells = 108 selectable cells.
- Shuffle flow: split into halves, perform alternating swaps, rotate half one by 13, rotate half two by 17, concatenate, then rotate the whole string by 23 for each PIN iteration.
- Cell mapping: button/cell 1 maps to shuffled character index 0, button/cell 108 maps to index 107.
- Default PIN: 2023.


## Algorithm versions now included

The shared core and all GUI front ends now expose an algorithm selector with these options:

| UI option | Seed | Shuffle function family | Source compatibility |
|---|---|---|---|
| `version1_0 / seed1` | Original 108-character seed | simple rotate/swap shuffle | Original HTML behavior and uploaded MFC `gen1_shuffle` behavior |
| `version1_1 / seed1` | Original 108-character seed | enhanced rotate/swap shuffle | Uploaded MFC `gen1_1_shuffle` behavior |
| `version2_0 / seed2` | Second seed string from uploaded MFC source | simple rotate/swap shuffle | Uploaded MFC `gen2_shuffle` behavior |
| `version2_1 / seed2` | Second seed string from uploaded MFC source | enhanced rotate/swap shuffle | Uploaded MFC `gen2_1_shuffle` behavior |

The second seed string in the uploaded MFC source has 112 printable characters. The desktop matrix still has 108 cells, so the version2_0 and version2_1 matrix mapping uses the first 108 characters for button/cell output.

The exact seed 1 string is:

```text
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`
```

The exact seed 2 source string is:

```text
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\:\";'<>?,./^&*()_+-={}|[]";
```

Validation vector for PIN `2023` with `version1_0 / seed1`:

```text
HCFMDOB/9S7'5h3f1:`UQ+PeN/`.=<?*_$~sb220Yw6y8cIaK4xJzAvRt!rLpqnolmj;8;?W_-0-9+^d53i$':^G>E7,gZ6.k,4*>1<X=VuT
```


## Matrix button behavior

Unclicked matrix buttons are colored by matrix:

- Matrix 1: red `#FF2A2A`
- Matrix 2: green `#55D400`
- Matrix 3: blue `#37abc8`

When a matrix button is clicked, the generated character is still appended to the password, but the clicked button returns to the default system button color. Matrix buttons no longer display `OFF` or `ON` labels.

## Platform implementations

| Platform | GUI API / framework | Language | Project files |
|---|---|---|---|
| Windows | Native Win32 API | C | Visual Studio 2022 `.sln/.vcxproj`, NMake `Makefile`, CMake |
| Linux | GTK+ 3 | C | Makefile, CMake, Anjuta project file |
| macOS default | Native AppKit | Swift | Makefile, CMake, native Xcode `.xcodeproj`, DMG script |
| macOS retained alternate | Swing | Java | Makefile, CMake, Xcode external-build project, NetBeans project, `.app` bundle and DMG script |

## Build commands

### Shared algorithm test

```sh
make core-test
```

### Windows / Visual Studio

Open:

```text
windows\CrypticPasswordWin32.sln
```

Build `Release|x64` in Visual Studio 2022.

From a Visual Studio Developer Command Prompt:

```bat
cd windows
nmake /f Makefile CONFIG=Release
```

CMake option:

```bat
cmake -S windows -B windows\build-cmake -G "Visual Studio 17 2022" -A x64
cmake --build windows\build-cmake --config Release
```

### Linux / GTK+

Debian/Ubuntu dependencies:

```sh
sudo apt install build-essential pkg-config libgtk-3-dev cmake
```

Build with Make:

```sh
cd linux
make
./build/crypticpassword-gtk
```

Build with CMake:

```sh
cmake -S linux -B linux/build-cmake
cmake --build linux/build-cmake
```

Open the Anjuta file:

```text
linux/anjuta/CrypticPassword.anjuta
```

### macOS / native Swift AppKit

Build on macOS:

```sh
cd mac
make app
make run
make dmg
```

Open the Xcode project:

```text
mac/xcode/CrypticPasswordSwift.xcodeproj
```

CMake option on macOS:

```sh
cmake -S mac -B mac/build-xcode -G Xcode
cmake --build mac/build-xcode --config Release
cmake --build mac/build-xcode --config Release --target package
```

`make dmg` creates:

```text
mac/dist/CrypticPassword-macos-swift.dmg
```

Swift algorithm-only validation, usable on non-macOS hosts that have Swift installed:

```sh
cd mac
make swift-core-test
```

### macOS retained Java Swing project

The Swing implementation is retained here:

```text
mac/swing
```

Build and run:

```sh
cd mac/swing
make app
make run
```

Open the NetBeans project:

```text
mac/swing/netbeans/CrypticPasswordSwingNB
```

Open the retained Swing Xcode external-build project:

```text
mac/swing/xcode/CrypticPasswordSwing.xcodeproj
```

## Installer/package creation

### Windows installers

Two installer definitions are included:

- WiX MSI: `windows/installer/CrypticPassword.wxs`
- Inno Setup EXE installer: `windows/installer/CrypticPassword.iss`

Build helper:

```powershell
cd windows\installer
.\build_installer.ps1 -Configuration Release
```

The script builds the Visual Studio solution first, then builds MSI/EXE installers when WiX Toolset and/or Inno Setup are installed.

### Linux installers

DEB:

```sh
cd linux
./packaging/build_deb.sh
```

RPM:

```sh
cd linux
./packaging/build_rpm.sh
```

### macOS DMG

Native Swift/AppKit DMG:

```sh
cd mac
make dmg
```

Retained Swing DMG:

```sh
cd mac/swing
make dmg
```

DMG creation uses `hdiutil`, so it must be run on macOS.

## Files of interest

- `common/crypticpassword_core.c` and `.h`: exact shared C implementation of the HTML algorithm.
- `tests/test_core.c`: verifies both seeds, all four algorithm versions, 3-matrix constants, and test vectors.
- `windows/src/main_win32.c`: native Win32 GUI.
- `linux/src/main_gtk.c`: GTK+ GUI.
- `mac/src/swift/CrypticPasswordApp.swift`: native macOS Swift/AppKit GUI.
- `mac/tests/CrypticPasswordSwiftCoreTest.swift`: Swift validation target for all four algorithm versions.
- `mac/swing/src/CrypticPasswordSwing.java`: retained Swing GUI.
- `mac/swing/netbeans/CrypticPasswordSwingNB`: NetBeans project for retained Swing version.
- `docs/original/CrypticPassword.html`: original uploaded HTML source kept for reference.
- `docs/original/CrypticPasswordDlg.cpp`: uploaded MFC source used for version1_1, version2_0, version2_1, and seed2.

## Security note

The original HTML says the Generation Two seed string is for password generation only and cautions not to use it as a general crypto primitive. This package preserves the algorithm exactly for compatibility; it does not claim the algorithm is cryptographically equivalent to modern password managers or password-based key derivation systems.

## iOS 14+ UIKit project

Version 1.5.0 includes a native Swift/UIKit iOS application under `ios/`.
Open `ios/xcode/CrypticPasswordiOS.xcodeproj` in Xcode, or run `cd ios && make build` on macOS with Xcode installed.
The iOS app preserves the same four algorithms, seed strings, three matrices, and selected-button system-default toggle behavior as the desktop versions.


## Android 12+

Version 1.5.0 includes a native Android SDK implementation under `android/`. It uses Android UI widgets, minSdk 31, and includes Android Studio/Gradle project files plus APK/AAB packaging helper scripts.
