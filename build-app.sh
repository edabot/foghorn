#!/bin/bash
set -e

APP_NAME="Reminder"
APP_DIR="${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp .build/release/${APP_NAME} "${APP_DIR}/Contents/MacOS/"
cp Sources/Reminder/Info.plist "${APP_DIR}/Contents/"

echo "Done! ${APP_DIR} is ready."
echo ""
echo "To distribute: zip or drag Reminder.app anywhere."
echo "First-time recipients: right-click → Open to bypass Gatekeeper."
