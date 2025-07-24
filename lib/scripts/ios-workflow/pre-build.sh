#!/bin/bash

# iOS Workflow Pre-Build Script
# Simple and direct pre-build setup

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🚀 Starting iOS Workflow Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"

# Pre-build cleanup
echo "🧹 Pre-build cleanup..."
flutter clean > /dev/null 2>&1 || log_warn "⚠️ flutter clean failed (continuing)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

# Initialize keychain
echo "🔐 Initialize keychain for codesigning..."
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."
PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"
PROFILE_PATH="$PROFILES_HOME/$PROFILE_SPECIFIER_UUID.mobileprovision"
echo ${CM_PROVISIONING_PROFILE} | base64 --decode > "$PROFILE_PATH"
echo "Saved provisioning profile $PROFILE_PATH"

# Extract UUID and Bundle ID from provisioning profile
security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist | cut -d '.' -f 2-)

if [[ -z "$UUID" ]]; then
  log_error "❌ Missing required variable: UUID"
  exit 1
fi

if [[ -z "$BUNDLE_ID" ]]; then
  log_error "❌ Missing required variable: BUNDLE_ID"
  exit 1
fi

echo "UUID: $UUID"
echo "Bundle Identifier: $BUNDLE_ID"

# Setup certificate
echo $CM_CERTIFICATE | base64 --decode > /tmp/certificate.p12
keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password $CM_CERTIFICATE_PASSWORD

# Validate signing identity
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "$CM_DISTRIBUTION_TYPE")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
  log_error "❌ No valid $CM_DISTRIBUTION_TYPE signing identities found in keychain. Exiting build."
  exit 1
else
  log_success "✅ Found $IDENTITY_COUNT valid $CM_DISTRIBUTION_TYPE identity(ies) in keychain."
fi

# Install Flutter dependencies
log_info "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

# Run CocoaPods commands
log_info "📦 Running CocoaPods commands..."

# Backup and remove Podfile.lock if it exists
if [ -f "ios/Podfile.lock" ]; then
  cp ios/Podfile.lock ios/Podfile.lock.backup
  log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
  rm ios/Podfile.lock
  log_info "🗑️ Removed original Podfile.lock"
fi

if ! command -v pod &>/dev/null; then
  log_error "CocoaPods is not installed!"
  exit 1
fi

pushd ios > /dev/null || { log_error "Failed to enter ios directory"; exit 1; }

log_info "🔄 Running: pod install"
if pod install > /dev/null 2>&1; then
  log_success "✅ pod install completed successfully"
else
  log_error "❌ pod install failed"
  popd > /dev/null
  exit 1
fi

popd > /dev/null

log_success "✅ CocoaPods commands completed"

# Update bundle identifier
OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="$BUNDLE_ID"

# Update in project.pbxproj
find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in Info.plist
find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in entitlements files
find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

log_success "✅ Bundle Identifier updated to $NEW_BUNDLE_ID"

# Update release.xcconfig
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
log_info "🔧 Updating release.xcconfig with dynamic signing values..."

# Remove any previous entries for these keys to avoid duplicates
sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH"
sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH"
sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH"
sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH"
sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH"

# Append updated values
{
  echo "CODE_SIGN_STYLE = $CODE_SIGNING_STYLE"
  echo "DEVELOPMENT_TEAM = $APPLE_TEAM_ID"
  echo "PROVISIONING_PROFILE_SPECIFIER = $UUID"
  echo "CODE_SIGN_IDENTITY = $CM_DISTRIBUTION_TYPE"
  echo "PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID"
} >> "$XC_CONFIG_PATH"

log_success "✅ release.xcconfig updated"

# Setup code signing settings on Xcode project
log_info "Set up code signing settings on Xcode project"
xcode-project use-profiles

log_success "🎉 iOS Pre-Build Setup completed successfully!" 