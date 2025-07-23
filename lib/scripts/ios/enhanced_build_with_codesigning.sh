#!/bin/bash

# Enhanced iOS Build with Codesigning Script
# Combines akash_build.sh codesigning approach with existing functionality

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🚀 Starting Enhanced iOS Build with Codesigning..."

# Validate required environment variables
log_info "🔍 Validating required environment variables..."

REQUIRED_VARS=(
  "CM_PROVISIONING_PROFILE"
  "CM_CERTIFICATE" 
  "CM_CERTIFICATE_PASSWORD"
  "APPLE_TEAM_ID"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING_VARS+=("$var")
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  log_error "❌ Missing required environment variables:"
  for var in "${MISSING_VARS[@]}"; do
    log_error "   - $var"
  done
  log_error "Please ensure all required variables are set in codemagic.yaml"
  exit 1
fi

log_success "✅ All required environment variables are set"

# Validate Flutter project setup
log_info "🔍 Validating Flutter project setup..."

if [ ! -f "pubspec.yaml" ]; then
  log_error "❌ pubspec.yaml not found. Are you in the correct directory?"
  exit 1
fi

if [ ! -d "ios" ]; then
  log_error "❌ ios directory not found. This doesn't appear to be a Flutter iOS project."
  exit 1
fi

if [ ! -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
  log_error "❌ iOS project file not found. iOS project may not be properly configured."
  exit 1
fi

log_success "✅ Flutter project structure is valid"

# Initialize keychain for codesigning
echo "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."

PROFILE_Specifier_UUID=$(uuidgen)
CM_PROVISIONING_PROFILE="${CM_PROVISIONING_PROFILE:-}"
PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"
PROFILE_PATH="$PROFILES_HOME/$PROFILE_Specifier_UUID.mobileprovision"

if [ -n "$CM_PROVISIONING_PROFILE" ]; then
  echo "$CM_PROVISIONING_PROFILE" | base64 --decode > "$PROFILE_PATH"
  echo "Saved provisioning profile $PROFILE_PATH"
else
  log_error "CM_PROVISIONING_PROFILE is not set"
  exit 1
fi

# Extract the embedded plist from the provisioning profile
security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist

# Extract UUID and Bundle ID
UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist)
BUNDLE_ID_EXTRACTED=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist | cut -d '.' -f 2-)

if [[ -z "$UUID" ]]; then
  log_error "Missing required variable: UUID"
  exit 1
fi

if [[ -z "$BUNDLE_ID_EXTRACTED" ]]; then
  log_error "Missing required variable: BUNDLE_ID_EXTRACTED"
  exit 1
fi

echo "UUID: $UUID"
echo "Bundle Identifier: $BUNDLE_ID_EXTRACTED"

# Setup certificate
CM_CERTIFICATE="${CM_CERTIFICATE:-}"
CM_CERTIFICATE_PASSWORD="${CM_CERTIFICATE_PASSWORD:-}"

if [ -n "$CM_CERTIFICATE" ] && [ -n "$CM_CERTIFICATE_PASSWORD" ]; then
  echo "$CM_CERTIFICATE" | base64 --decode > /tmp/certificate.p12
  keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password "$CM_CERTIFICATE_PASSWORD"
else
  log_error "CM_CERTIFICATE or CM_CERTIFICATE_PASSWORD is not set"
  exit 1
fi

# Validate signing identity
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "${CM_DISTRIBUTION_TYPE:-Apple Distribution}")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
  log_error "No valid ${CM_DISTRIBUTION_TYPE:-Apple Distribution} signing identities found in keychain. Exiting build."
  exit 1
else
  log_success "Found $IDENTITY_COUNT valid ${CM_DISTRIBUTION_TYPE:-Apple Distribution} identity(ies) in keychain."
fi

# Setup code signing settings on Xcode project
echo "Set up code signing settings on Xcode project"
xcode-project use-profiles

# Function to run CocoaPods commands
run_cocoapods_commands() {
  # Backup and remove Podfile.lock if it exists
  if [ -f "ios/Podfile.lock" ]; then
    cp ios/Podfile.lock ios/Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
    rm ios/Podfile.lock
    log_info "🗑️ Removed original Podfile.lock"
  else
    log_warn "⚠️ Podfile.lock not found — skipping backup and removal"
  fi

  log_info "📦 Running CocoaPods commands..."

  if ! command -v pod &>/dev/null; then
    log_error "CocoaPods is not installed!"
    exit 1
  fi

  pushd ios > /dev/null || { log_error "Failed to enter ios directory"; return 1; }

  log_info "🔄 Running: pod install"
  if pod install > /dev/null 2>&1; then
    log_success "✅ pod install completed successfully"
  else
    log_error "❌ pod install failed"
    popd > /dev/null
    return 1
  fi

  if [ "${RUN_POD_UPDATE:-false}" = "true" ]; then
    log_info "🔄 Running: pod update"
    if ! pod update > /dev/null 2>&1; then
      log_warn "⚠️ pod update had issues (continuing)"
    fi
  fi

  popd > /dev/null
  log_success "✅ CocoaPods commands completed"
}

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

run_cocoapods_commands

# Update bundle identifier if needed
OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="${BUNDLE_ID:-$BUNDLE_ID_EXTRACTED}"

# Update in project.pbxproj
find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in Info.plist (just in case it's hardcoded)
find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in any entitlements files
find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

log_success "Bundle Identifier updated to $NEW_BUNDLE_ID"

# Update release.xcconfig with dynamic signing values
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
echo "🔧 Updating release.xcconfig with dynamic signing values..."

# Remove any previous entries for these keys to avoid duplicates
sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH"
sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH"
sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH"
sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH"
sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH"

# Append updated values
{
  echo "CODE_SIGN_STYLE = ${CODE_SIGNING_STYLE:-manual}"
  echo "DEVELOPMENT_TEAM = ${APPLE_TEAM_ID:-}"
  echo "PROVISIONING_PROFILE_SPECIFIER = $UUID"
  echo "CODE_SIGN_IDENTITY = ${CM_DISTRIBUTION_TYPE:-Apple Distribution}"
  echo "PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID"
} >> "$XC_CONFIG_PATH"

echo "✅ release.xcconfig updated:"
cat "$XC_CONFIG_PATH"

# Backup the current project before build
zip -r project_backup.zip . -x "build/*" ".dart_tool/*" ".git/*" "output/*"

# Build Flutter app (single attempt for time savings)
log_info "📱 Building Flutter iOS app in release mode..."

# Check if required environment variables are set
if [ -z "${VERSION_NAME:-}" ]; then
  log_warn "VERSION_NAME not set, using default"
  VERSION_NAME="1.0.0"
fi

if [ -z "${VERSION_CODE:-}" ]; then
  log_warn "VERSION_CODE not set, using default"
  VERSION_CODE="1"
fi

# Build Flutter app with better error handling
log_info "Running: flutter build ios --release --no-codesign --build-name=$VERSION_NAME --build-number=$VERSION_CODE"

if flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE"; then
  log_success "✅ Flutter build completed successfully"
else
  log_error "❌ Flutter build failed"
  log_error "📋 Build logs:"
  cat flutter_build.log 2>/dev/null || echo "No flutter_build.log found"
  log_error "🔍 Checking Flutter doctor..."
  flutter doctor -v
  log_error "🔍 Checking iOS project configuration..."
  ls -la ios/
  log_error "🔍 Checking Runner.xcworkspace..."
  ls -la ios/Runner.xcworkspace 2>/dev/null || echo "Runner.xcworkspace not found"
  exit 1
fi

# Archive app with Xcode
log_info "📦 Archiving app with Xcode..."

# Check if workspace exists
if [ ! -d "ios/Runner.xcworkspace" ]; then
  log_error "❌ ios/Runner.xcworkspace not found"
  log_error "🔍 Available files in ios/:"
  ls -la ios/
  exit 1
fi

mkdir -p build/ios/archive

echo "Current directory: $(pwd)"
ls -l ios/Runner.xcworkspace

log_info "Running: xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/ios/archive/Runner.xcarchive -destination 'generic/platform=iOS' archive DEVELOPMENT_TEAM=$APPLE_TEAM_ID"

if xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  archive \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}"; then
  log_success "✅ Xcode archive completed successfully"
else
  log_error "❌ Xcode archive failed"
  log_error "📋 Archive logs:"
  cat xcodebuild_archive.log 2>/dev/null || echo "No xcodebuild_archive.log found"
  log_error "🔍 Checking archive directory:"
  ls -la build/ios/archive/ 2>/dev/null || echo "Archive directory not found"
  exit 1
fi

# Create ExportOptions.plist
log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${PROFILE_TYPE:-app-store}</string>
  <key>teamID</key>
  <string>${APPLE_TEAM_ID:-}</string>
  <key>signingStyle</key>
  <string>${CODE_SIGNING_STYLE_EXPORT:-manual}</string>
  <key>provisioningProfiles</key>
    <dict>
      <key>$NEW_BUNDLE_ID</key>
      <string>$UUID</string>
    </dict>
  <key>uploadBitcode</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
EOF

# Export IPA
log_info "�� Exporting IPA..."

# Check if archive exists
if [ ! -d "build/ios/archive/Runner.xcarchive" ]; then
  log_error "❌ Archive not found at build/ios/archive/Runner.xcarchive"
  log_error "🔍 Available archives:"
  find build/ios/archive -name "*.xcarchive" 2>/dev/null || echo "No archives found"
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-output/ios}"
mkdir -p "$OUTPUT_DIR"

log_info "Running: xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportPath $OUTPUT_DIR -exportOptionsPlist ios/ExportOptions.plist"

if xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath "$OUTPUT_DIR" \
  -exportOptionsPlist ios/ExportOptions.plist; then
  log_success "✅ IPA export completed successfully"
else
  log_error "❌ IPA export failed"
  log_error "📋 Export logs:"
  cat xcodebuild_export.log 2>/dev/null || echo "No xcodebuild_export.log found"
  log_error "🔍 Checking output directory:"
  ls -la "$OUTPUT_DIR" 2>/dev/null || echo "Output directory not found"
  exit 1
fi

# Find and rename IPA
IPA_PATH=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -n 1)

if [ -f "$IPA_PATH" ]; then
  mv "$IPA_PATH" "$OUTPUT_DIR/${APP_NAME:-Runner}.ipa"
  log_success "✅ IPA created: $OUTPUT_DIR/${APP_NAME:-Runner}.ipa"
else
  log_error "❌ IPA file not found. Build may have failed."
  exit 1
fi

log_success "🎉 Enhanced iOS build process completed successfully!" 