PROJECT=xcode/CrypticPasswordiOS.xcodeproj
SCHEME=CrypticPasswordiOS
CONFIGURATION=Debug
SDK=iphonesimulator
DERIVED_DATA=build/DerivedData
ARCHIVE_PATH=build/CrypticPasswordiOS.xcarchive
EXPORT_PATH=build/export

.PHONY: build clean archive ipa

build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -sdk $(SDK) -derivedDataPath $(DERIVED_DATA) build

archive:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -sdk iphoneos -archivePath $(ARCHIVE_PATH) archive

ipa: archive
	xcodebuild -exportArchive -archivePath $(ARCHIVE_PATH) -exportPath $(EXPORT_PATH) -exportOptionsPlist packaging/ExportOptions.plist

clean:
	rm -rf build
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
