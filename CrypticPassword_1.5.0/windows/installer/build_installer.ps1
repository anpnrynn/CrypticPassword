param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root

msbuild .\CrypticPasswordWin32.sln /p:Configuration=$Configuration /p:Platform=x64

if (Get-Command candle.exe -ErrorAction SilentlyContinue) {
    Push-Location installer
    candle.exe CrypticPassword.wxs
    light.exe -ext WixUIExtension -o build\CrypticPassword-$Configuration.msi CrypticPassword.wixobj
    Pop-Location
} else {
    Write-Warning "WiX candle.exe not found. Install WiX Toolset to build the MSI."
}

if (Get-Command ISCC.exe -ErrorAction SilentlyContinue) {
    Push-Location installer
    ISCC.exe CrypticPassword.iss
    Pop-Location
} else {
    Write-Warning "Inno Setup ISCC.exe not found. Install Inno Setup to build the setup EXE."
}

Pop-Location
