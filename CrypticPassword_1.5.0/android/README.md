# CrypticPassword for Android 12+

Native Android implementation of CrypticPassword using the Android SDK UI widgets.

## Requirements

- Android Studio or Android SDK command-line tools
- Gradle with Android Gradle Plugin support
- Android 12+ device/emulator; `minSdk 31`

## Build

```sh
cd android
make build
```

The debug APK will be generated at:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

## Release packaging

Use `packaging/build_release_aab.sh` to create an Android App Bundle. Configure signing in Android Studio or add your local signing config before producing a release artifact.

## Included behavior

- `version1_0`, `version1_1`, `version2_0`, `version2_1` algorithms.
- Original seed string and second seed string.
- Three 6x6 matrices.
- Matrix 1 red `#FF2A2A`, matrix 2 green `#55D400`, matrix 3 blue `#37abc8`.
- Blank matrix buttons; clicked cells return to the native Android default button background.
