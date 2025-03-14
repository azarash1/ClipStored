#!/bin/bash

# Clean previous builds
rm -rf .build
rm -rf ClipSync.app

# Build the app
swift build -c release --product ClipSync

# Create app bundle structure
mkdir -p ClipSync.app/Contents/MacOS
mkdir -p ClipSync.app/Contents/Resources

# Copy the binary
cp .build/release/ClipSync ClipSync.app/Contents/MacOS/

# Copy Info.plist
cp Sources/ClipSync/Resources/Info.plist ClipSync.app/Contents/

# Copy entitlements
cp Sources/ClipSync/ClipSync.entitlements ClipSync.app/Contents/

# Make the binary executable
chmod +x ClipSync.app/Contents/MacOS/ClipSync

# Remove quarantine attribute
xattr -cr ClipSync.app

# Sign the app with entitlements
codesign --force --deep --sign - --entitlements Sources/ClipSync/ClipSync.entitlements ClipSync.app

# Verify the app
codesign -vv ClipSync.app

echo "App bundle created at ./ClipSync.app" 