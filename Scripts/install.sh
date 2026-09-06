#!/bin/sh
# Build LinkShelf and install it where WidgetKit will find the extension.
# ponytail: ad-hoc signing and a straight copy; replace with a signed,
# notarized package when this ships to anyone else.
set -e
cd "$(dirname "$0")/.."
xcodebuild -project LinkShelf.xcodeproj -scheme LinkShelf \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DD \
  -configuration Debug build CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual
rm -rf /Applications/LinkShelf.app
cp -R build/DD/Build/Products/Debug/LinkShelf.app /Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f /Applications/LinkShelf.app
open /Applications/LinkShelf.app
echo "Installed. Right-click the desktop > Edit Widgets > LinkShelf."
