# CrypticPassword for iOS 14+

This is a native Swift/UIKit implementation of CrypticPassword for iOS 14 and newer.
It mirrors the desktop project behavior:

- Four algorithm choices: `version1_0`, `version1_1`, `version2_0`, `version2_1`.
- Both seed strings from the HTML and MFC/native sources.
- Three 6 x 6 matrices, navigated with Back and Next.
- Matrix colors: red `#FF2A2A`, green `#55D400`, blue `#37abc8`.
- Clicking a matrix cell appends the matching shuffled character to the password and returns the cell to system-default button appearance.
- No ON/OFF button labels are used.

## Build in Xcode

Open:

```text
ios/xcode/CrypticPasswordiOS.xcodeproj
```

Select the `CrypticPasswordiOS` scheme, choose an iOS 14+ simulator or a signed device target, then build and run.

## Build from command line

```sh
cd ios
make build
```

This builds for `iphonesimulator` by default.

## Archive / IPA export

Apple signing is required for a real iOS app archive or IPA. Update `packaging/ExportOptions.plist` and the Xcode project signing team/bundle identifier, then run:

```sh
cd ios
make archive
make ipa
```

## Xcode file-reference repair retained

The Xcode project now references Swift sources with `SOURCE_ROOT` paths from `ios/xcode`:

- `../src/AppDelegate.swift`
- `../src/SceneDelegate.swift`
- `../src/CrypticPasswordAlgorithm.swift`
- `../src/CrypticPasswordViewController.swift`
- `../Info.plist`

This fixes Xcode's "Failed to open document" error caused by the previous broken `../../src/...` references.
