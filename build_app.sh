#!/bin/bash
set -e

APP_NAME="LeaveWorkReminder"
DISPLAY_NAME="퇴근 알리미"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR=".build/dmg"
DMG_PATH=".build/${APP_NAME}.dmg"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building (Release)... ==="
swift build -c release

echo "=== Creating app bundle... ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 바이너리 복사
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 아이콘 복사
if [ -f "$SCRIPT_DIR/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "  아이콘 복사 완료"
fi

# Info.plist 생성
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.yoo.LeaveWorkReminder</string>
    <key>CFBundleName</key>
    <string>LeaveWorkReminder</string>
    <key>CFBundleDisplayName</key>
    <string>퇴근 알리미</string>
    <key>CFBundleExecutable</key>
    <string>LeaveWorkReminder</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>
            <key>ws.bus.go.kr</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>
        </dict>
    </dict>
</dict>
</plist>
PLIST

echo "=== Creating DMG... ==="
rm -rf "$DMG_DIR" "$DMG_PATH"
mkdir -p "$DMG_DIR"
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$DISPLAY_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_DIR"

echo ""
echo "=== 완료! ==="
echo "앱 번들: $APP_BUNDLE"
echo "DMG 파일: $DMG_PATH"
echo ""
echo "실행: open $APP_BUNDLE"
echo "설치: open $DMG_PATH → 앱을 Applications로 드래그"
