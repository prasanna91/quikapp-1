#!/bin/bash

# Simple iOS Build Script - Following akash_build.sh method
# Downloads assets, builds, archives, and exports IPA with proper codesigning

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🚀 Starting Simple iOS Build with akash_build.sh method..."

# Initialize keychain for codesigning
echo "🔐 Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

# Setup provisioning profile
log_info "Setting up provisioning profile..."

PROFILE_Specifier_UUID="${PROFILE_SPECIFIER_UUID:-$(uuidgen)}"
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

# Download assets
echo "📥 Downloading assets..."
if [ -f "lib/scripts/ios/download_assets.sh" ]; then
  chmod +x lib/scripts/ios/download_assets.sh
  ./lib/scripts/ios/download_assets.sh
fi

# Debug: Check iOS project structure
log_info "🔍 Checking iOS project structure..."
if [ -d "ios" ]; then
  log_info "✅ ios directory exists"
  ls -la ios/
  if [ -f "ios/Podfile" ]; then
    log_info "✅ Podfile exists"
    head -10 ios/Podfile
  else
    log_error "❌ Podfile not found"
  fi
  if [ -d "ios/Runner.xcworkspace" ]; then
    log_info "✅ Runner.xcworkspace exists"
  else
    log_error "❌ Runner.xcworkspace not found"
  fi
else
  log_error "❌ ios directory not found"
  exit 1
fi

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

  # Check if Podfile exists
  if [ ! -f "Podfile" ]; then
    log_error "❌ Podfile not found in ios directory"
    popd > /dev/null
    return 1
  fi

  log_info "🔄 Running: pod install"
  # Run pod install with visible output for debugging
  if pod install 2>&1 | tee /tmp/pod_install.log; then
    log_success "✅ pod install completed successfully"
  else
    log_error "❌ pod install failed"
    log_error "Pod install error log:"
    cat /tmp/pod_install.log | tail -20
    popd > /dev/null
    return 1
  fi

  if [ "${RUN_POD_UPDATE:-false}" = "true" ]; then
    log_info "🔄 Running: pod update"
    if ! pod update 2>&1 | tee /tmp/pod_update.log; then
      log_warn "⚠️ pod update had issues (continuing)"
      log_warn "Pod update error log:"
      cat /tmp/pod_update.log | tail -10
    fi
  fi

  popd > /dev/null
  log_success "✅ CocoaPods commands completed"
}

# Update display name
PLIST_PATH="ios/Runner/Info.plist"
DISPLAY_NAME="${APP_DISPLAY_NAME:-Runner}"

# Check if key exists, else add it
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
  && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$DISPLAY_NAME'" "$PLIST_PATH" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$DISPLAY_NAME'" "$PLIST_PATH"

# Update bundle identifier
OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="${BUNDLE_ID:-$BUNDLE_ID_EXTRACTED}"

# Update in project.pbxproj
find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in Info.plist (just in case it's hardcoded)
find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in any entitlements files
find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

log_success "Bundle Identifier updated to $NEW_BUNDLE_ID"

# Install Flutter dependencies (skip if already done in pre-build)
echo "📦 Installing Flutter dependencies..."
if flutter pub get 2>&1 | tee /tmp/flutter_pub_get.log; then
  log_success "✅ flutter pub get completed successfully"
else
  log_error "❌ flutter pub get failed"
  log_error "Flutter pub get error log:"
  cat /tmp/flutter_pub_get.log | tail -20
  exit 1
fi

# Skip CocoaPods since it's already handled in pre-build
log_info "📦 Skipping CocoaPods (already handled in pre-build)..."

# Fix CocoaPods repository and reinstall if needed
log_info "📦 Ensuring CocoaPods repository is up to date..."

# Check if CocoaPods is available
if ! command -v pod &>/dev/null; then
  log_error "❌ CocoaPods is not installed or not in PATH"
  log_info "📦 Installing CocoaPods..."
  sudo gem install cocoapods || {
    log_error "❌ Failed to install CocoaPods"
    exit 1
  }
fi

cd ios

# Run comprehensive CocoaPods integration fix if available
if [ -f "../lib/scripts/ios/cocoapods_integration_fix.sh" ]; then
  log_info "🔧 Running comprehensive CocoaPods integration fix..."
  chmod +x ../lib/scripts/ios/cocoapods_integration_fix.sh
  if ../lib/scripts/ios/cocoapods_integration_fix.sh; then
    log_success "✅ CocoaPods integration fix completed"
  else
    log_warn "⚠️ CocoaPods integration fix had issues, continuing with manual approach..."
  fi
fi

# Run Firebase version conflict resolution if available
if [ -f "../lib/scripts/ios/fix_firebase_version_conflict.sh" ]; then
  log_info "🔥 Running Firebase version conflict resolution..."
  chmod +x ../lib/scripts/ios/fix_firebase_version_conflict.sh
  if ../lib/scripts/ios/fix_firebase_version_conflict.sh; then
    log_success "✅ Firebase version conflict resolution completed"
  else
    log_warn "⚠️ Firebase version conflict resolution had issues, continuing..."
  fi
fi

# Update Firebase versions if needed
if [ -f "../lib/scripts/ios/update_firebase_versions.sh" ]; then
  log_info "📦 Checking and updating Firebase versions..."
  chmod +x ../lib/scripts/ios/update_firebase_versions.sh
  if ../lib/scripts/ios/update_firebase_versions.sh; then
    log_success "✅ Firebase versions updated"
  else
    log_warn "⚠️ Firebase version update had issues, continuing..."
  fi
fi

# Update CocoaPods repository
log_info "🔄 Updating CocoaPods repository..."
if pod repo update --silent; then
  log_success "✅ CocoaPods repository updated"
else
  log_warn "⚠️ CocoaPods repository update failed, continuing..."
fi

# Check if Podfile.lock exists and is recent
if [ -f "Podfile.lock" ]; then
  log_info "📋 Podfile.lock exists, checking if reinstall is needed..."
  
  # Check for Firebase version conflicts
  if grep -q "Firebase/Messaging.*11.15.0" "Podfile.lock"; then
    log_warn "⚠️ Firebase version conflict detected in Podfile.lock"
    log_info "🗑️ Removing Podfile.lock to resolve Firebase version conflicts..."
    rm -f Podfile.lock
    rm -rf Pods
  fi
  
  # Try to install with repo update
  if pod install --repo-update --clean-install; then
    log_success "✅ CocoaPods installed successfully with repo update"
  else
    log_warn "⚠️ CocoaPods install with repo update failed, trying alternative approach..."
    
    # Clear CocoaPods cache and try again
    pod cache clean --all || true
    
    if pod install --repo-update --clean-install; then
      log_success "✅ CocoaPods installed successfully with cache cleanup"
    else
      log_error "❌ CocoaPods installation failed completely"
      cd ..
      exit 1
    fi
  fi
else
  log_info "📋 No Podfile.lock found, performing fresh installation..."
  
  if pod install --repo-update --clean-install; then
    log_success "✅ CocoaPods installed successfully"
  else
    log_error "❌ CocoaPods installation failed"
    cd ..
    exit 1
  fi
fi

# Additional cleanup and reinstall if still having issues
if [ ! -d "Pods" ] || [ ! -f "Podfile.lock" ]; then
  log_warn "⚠️ Pods directory or Podfile.lock missing, performing complete reinstall..."
  
  # Remove existing Pods and lock file
  rm -rf Pods Podfile.lock
  
  # Clear all CocoaPods caches
  pod cache clean --all || true
  pod deintegrate || true
  
  # Fresh install
  if pod install --repo-update --clean-install; then
    log_success "✅ Complete CocoaPods reinstall successful"
  else
    log_error "❌ Complete CocoaPods reinstall failed"
    cd ..
    exit 1
  fi
fi

cd ..

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

# Build Flutter app
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
  --build-name="${VERSION_NAME:-1.0.0}" \
  --build-number="${VERSION_CODE:-1}" \
  2>&1 | tee flutter_build.log | grep -E "(Building|Error|FAILURE|warning|Warning|error|Exception|\.dart)"

# Archive app with Xcode
log_info "📦 Archiving app with Xcode..."
mkdir -p build/ios/archive

echo "Current directory: $(pwd)"
ls -l ios/Runner.xcworkspace

xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  -destination 'generic/platform=iOS' \
  archive \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}" \
  2>&1 | tee xcodebuild_archive.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

# Create ExportOptions.plist
log_info "🛠️ Writing ExportOptions.plist..."
cat > ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>destination</key>
  <string>export</string>
  <key>generateAppStoreInformation</key>
  <false/>
  <key>manageAppVersionAndBuildNumber</key>
  <true/>
  <key>method</key>
  <string>app-store-connect</string>
  <key>provisioningProfiles</key>
    <dict>
      <key>$NEW_BUNDLE_ID</key>
      <string>$UUID</string>
    </dict>
  <key>signingCertificate</key>
  <string>${CM_DISTRIBUTION_TYPE:-Apple Distribution}</string>
  <key>signingStyle</key>
  <string>${CODE_SIGNING_STYLE_EXPORT:-manual}</string>
  <key>teamID</key>
  <string>${APPLE_TEAM_ID:-}</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>testFlightInternalTestingOnly</key>
  <false/>
  <key>uploadSymbols</key>
  <true/>
  <key>compileBitcode</key>
  <false/>
  <key>uploadBitcode</key>
  <false/>
</dict>
</plist>
EOF

# Export IPA
log_info "📤 Exporting IPA..."
OUTPUT_DIR="${OUTPUT_DIR:-build/ios/output}"
mkdir -p "$OUTPUT_DIR"

xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath "$OUTPUT_DIR" \
  -exportOptionsPlist ios/ExportOptions.plist

# Find and rename IPA
IPA_PATH=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -n 1)

if [ -f "$IPA_PATH" ]; then
  mv "$IPA_PATH" "$OUTPUT_DIR/Runner.ipa"
  log_success "✅ IPA created: $OUTPUT_DIR/Runner.ipa"
else
  log_error "❌ IPA file not found. Build may have failed."
  exit 1
fi

log_success "🎉 Simple iOS build process completed successfully!" 