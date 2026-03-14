# Windows packaging (Inno Setup)

The GeoTag Windows installer is built with [Inno Setup](https://jrsoftware.org/isinfo.php).

## Local build

1. Build the app: `flutter build windows --release`
2. Install Inno Setup (winget: `winget install JRSoftware.InnoSetup`)
3. Run: `"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /DAppVersion=0.1.1 packaging\windows\installer.iss`
4. Output: `build\installer\GeoTag-Setup-0.1.1.exe`

## CI (Codemagic)

The `windows-release` workflow installs Inno Setup via winget/choco and runs the script automatically. Version is read from `pubspec.yaml` + `PROJECT_BUILD_NUMBER`.
