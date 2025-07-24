#!/bin/bash

# Increment Version Script
# Automatically increments bundle version to avoid TestFlight upload conflicts

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔢 Incrementing bundle version..."

# Get current version from pubspec.yaml
if [ -f "pubspec.yaml" ]; then
  CURRENT_VERSION=$(grep "version:" pubspec.yaml | head -1 | sed 's/version: //' | tr -d ' ')
  log_info "📋 Current version from pubspec.yaml: $CURRENT_VERSION"
else
  log_warn "⚠️ pubspec.yaml not found, using default version"
  CURRENT_VERSION="1.0.0"
fi

# Extract version components
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
VERSION_CODE=$(echo $CURRENT_VERSION | cut -d'+' -f2)

if [ -z "$VERSION_CODE" ]; then
  VERSION_CODE="1"
fi

# Increment version code
NEW_VERSION_CODE=$((VERSION_CODE + 1))
NEW_VERSION="$VERSION_NAME+$NEW_VERSION_CODE"

log_info "📋 Incrementing version: $CURRENT_VERSION → $NEW_VERSION"

# Update pubspec.yaml
if [ -f "pubspec.yaml" ]; then
  sed -i '' "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
  log_success "✅ Updated pubspec.yaml version to $NEW_VERSION"
fi

# Update iOS Info.plist if it exists
if [ -f "ios/Runner/Info.plist" ]; then
  # Update CFBundleShortVersionString (version name)
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NAME" ios/Runner/Info.plist 2>/dev/null || true
  
  # Update CFBundleVersion (version code)
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $NEW_VERSION_CODE" ios/Runner/Info.plist 2>/dev/null || true
  
  log_success "✅ Updated iOS Info.plist version to $VERSION_NAME ($NEW_VERSION_CODE)"
fi

# Export new version for use in other scripts
export VERSION_NAME="$VERSION_NAME"
export VERSION_CODE="$NEW_VERSION_CODE"
export NEW_VERSION="$NEW_VERSION"

log_success "✅ Version incremented successfully: $NEW_VERSION"
echo "VERSION_NAME=$VERSION_NAME"
echo "VERSION_CODE=$NEW_VERSION_CODE"
echo "NEW_VERSION=$NEW_VERSION" 