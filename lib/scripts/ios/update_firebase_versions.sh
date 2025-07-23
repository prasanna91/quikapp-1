#!/bin/bash

# Update Firebase Versions Script
# Updates Firebase dependencies to compatible versions

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔥 Updating Firebase versions to compatible ones..."

PUBSPEC_PATH="pubspec.yaml"

# Check if we're in the right directory
if [ ! -f "$PUBSPEC_PATH" ]; then
  log_error "❌ pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Create backup
cp "$PUBSPEC_PATH" "${PUBSPEC_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
log_success "✅ pubspec.yaml backed up"

# Update Firebase versions to compatible ones
log_info "📦 Updating Firebase versions..."

# Update firebase_core to a compatible version
sed -i '' 's/firebase_core: ^3.0.0/firebase_core: ^2.24.2/g' "$PUBSPEC_PATH"

# Update firebase_messaging to a compatible version
sed -i '' 's/firebase_messaging: ^15.0.0/firebase_messaging: ^14.7.10/g' "$PUBSPEC_PATH"

log_success "✅ Updated Firebase versions:"
log_info "   - firebase_core: ^2.24.2"
log_info "   - firebase_messaging: ^14.7.10"

# Update Flutter dependencies
log_info "📦 Updating Flutter dependencies..."
if flutter pub get; then
  log_success "✅ Flutter dependencies updated successfully"
else
  log_error "❌ Failed to update Flutter dependencies"
  exit 1
fi

# Clean iOS build
log_info "🧹 Cleaning iOS build..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock

log_success "✅ Firebase versions updated and build cleaned"
log_info "📋 Next step: Run pod install in ios directory" 