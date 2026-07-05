# CrypticPassword Java Swing Retained Project

This directory preserves the previous Java Swing macOS implementation.
It is no longer the default macOS app; the default macOS app is now the native Swift/AppKit project in `../`.

## Build with Make

```sh
cd mac/swing
make app
make run
make dmg
```

`make dmg` requires macOS `hdiutil`.

## Build with CMake

```sh
cmake -S mac/swing -B mac/swing/build-cmake
cmake --build mac/swing/build-cmake --target app
```

## Open in Xcode

```text
mac/swing/xcode/CrypticPasswordSwing.xcodeproj
```

This is an external-build Xcode project that delegates to the Swing Makefile.

## Open in NetBeans

```text
mac/swing/netbeans/CrypticPasswordSwingNB
```

The NetBeans project includes an Ant build file, `nbproject/project.xml`, and `nbproject/project.properties`.

## Algorithm menu and colors

The retained Swing app includes the same algorithm menu as the native app: `version1_0 / seed1`, `version1_1 / seed1`, `version2_0 / seed2`, and `version2_1 / seed2`. Matrix buttons are always colored red `#FF2A2A`, green `#55D400`, and blue `#37abc8` for matrices 1, 2, and 3.
