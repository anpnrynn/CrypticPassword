# CrypticPassword macOS Projects

The default macOS implementation is now a native Swift/AppKit application.
The previous Java Swing implementation is preserved under `mac/swing` and includes Makefile, CMake, Xcode external-build, and NetBeans project files.

## Native Swift/AppKit app

Build on macOS:

```sh
cd mac
make app
make run
make dmg
```

`make dmg` creates:

```text
mac/dist/CrypticPassword-macos-swift.dmg
```

Open the native Xcode project:

```text
mac/xcode/CrypticPasswordSwift.xcodeproj
```

CMake option on macOS:

```sh
cmake -S mac -B mac/build-xcode -G Xcode
cmake --build mac/build-xcode --config Release
cmake --build mac/build-xcode --config Release --target package
```

The CMake package target uses the DragNDrop generator to produce a DMG on macOS.

## Swift algorithm validation on non-macOS hosts

The AppKit GUI needs macOS, but the Swift algorithm can be checked anywhere Swift is installed:

```sh
cd mac
make swift-core-test
```

## Retained Java Swing project

Build and run:

```sh
cd mac/swing
make app
make run
```

Open in NetBeans:

```text
mac/swing/netbeans/CrypticPasswordSwingNB
```

## Algorithm menu and colors

The native Swift/AppKit app includes `version1_0 / seed1`, `version1_1 / seed1`, `version2_0 / seed2`, and `version2_1 / seed2`. Matrix buttons are always colored red `#FF2A2A`, green `#55D400`, and blue `#37abc8` for matrices 1, 2, and 3.
