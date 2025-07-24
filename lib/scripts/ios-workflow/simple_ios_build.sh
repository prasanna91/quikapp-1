#!/bin/bash

# Simple iOS Build Script
# Complete iOS workflow in a single script following akash_build.sh method
# Uses current environment variables and includes Dart-specific requirements

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🚀 Starting Simple iOS Build Workflow..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version 2>/dev/null || echo "Not installed")"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"

# =============================================================================
# PHASE 1: PRE-BUILD CLEANUP AND SETUP
# =============================================================================

echo "🧹 Phase 1: Pre-build cleanup and setup..."

# Pre-build cleanup
flutter clean > /dev/null 2>&1 || log_warn "⚠️ flutter clean failed (continuing)"
rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

# Initialize keychain for codesigning
log_info "🔐 Initialize keychain for codesigning..."
if command -v keychain &>/dev/null; then
  keychain initialize
  log_success "✅ Keychain initialized"
else
  log_warn "⚠️ keychain command not available (continuing without keychain initialization)"
  log_info "📋 This is normal in some CI/CD environments"
fi

# =============================================================================
# PHASE 2: ENVIRONMENT VARIABLES SETUP
# =============================================================================

echo "🔧 Phase 2: Environment variables setup..."

# Set default values for required variables
UUID="${UUID:-}"
BUNDLE_ID="${BUNDLE_ID:-}"
CM_DISTRIBUTION_TYPE="${CM_DISTRIBUTION_TYPE:-Apple Distribution}"
CODE_SIGNING_STYLE="${CODE_SIGNING_STYLE:-manual}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-1}"

# If UUID or BUNDLE_ID are not set, try to extract from provisioning profile
if [ -z "$UUID" ] || [ -z "$BUNDLE_ID" ]; then
  log_info "📋 Extracting UUID and BUNDLE_ID from provisioning profile..."
  
  PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
  if [ -d "$PROFILES_HOME" ]; then
    PROFILE_PATH=$(find "$PROFILES_HOME" -name "*.mobileprovision" | head -n 1)
    
    if [ ! -z "$PROFILE_PATH" ] && [ -f "$PROFILE_PATH" ]; then
      log_info "📋 Found provisioning profile: $PROFILE_PATH"
      
      # Extract UUID and Bundle ID from provisioning profile
      security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
      
      if [ -f "/tmp/profile.plist" ]; then
        UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
        BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
        
        if [ ! -z "$UUID" ]; then
          log_success "✅ Extracted UUID: $UUID"
        else
          log_warn "⚠️ Could not extract UUID from provisioning profile"
        fi
        
        if [ ! -z "$BUNDLE_ID" ]; then
          log_success "✅ Extracted BUNDLE_ID: $BUNDLE_ID"
        else
          log_warn "⚠️ Could not extract BUNDLE_ID from provisioning profile"
        fi
      else
        log_warn "⚠️ Could not decode provisioning profile"
      fi
    else
      log_warn "⚠️ No provisioning profile found"
    fi
  else
    log_warn "⚠️ Provisioning profiles directory not found"
  fi
fi

# Validate required variables
if [ -z "$UUID" ]; then
  log_error "❌ UUID is not set and could not be extracted from provisioning profile"
  exit 1
fi

if [ -z "$BUNDLE_ID" ]; then
  log_error "❌ BUNDLE_ID is not set and could not be extracted from provisioning profile"
  exit 1
fi

log_success "✅ Environment variables configured:"
log_info "   UUID: $UUID"
log_info "   BUNDLE_ID: $BUNDLE_ID"
log_info "   CM_DISTRIBUTION_TYPE: $CM_DISTRIBUTION_TYPE"
log_info "   CODE_SIGNING_STYLE: $CODE_SIGNING_STYLE"
log_info "   APPLE_TEAM_ID: $APPLE_TEAM_ID"

# =============================================================================
# PHASE 3: PROVISIONING PROFILE AND CERTIFICATE SETUP
# =============================================================================

echo "🔐 Phase 3: Provisioning profile and certificate setup..."

# Setup provisioning profile
log_info "Setting up provisioning profile..."
PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"
PROFILE_PATH="$PROFILES_HOME/$UUID.mobileprovision"

if [ ! -z "${CM_PROVISIONING_PROFILE:-}" ]; then
  echo ${CM_PROVISIONING_PROFILE} | base64 --decode > "$PROFILE_PATH"
  log_success "✅ Saved provisioning profile $PROFILE_PATH"
else
  log_warn "⚠️ CM_PROVISIONING_PROFILE not set, using existing profile"
fi

# Setup certificate
if [ ! -z "${CM_CERTIFICATE:-}" ] && [ ! -z "${CM_CERTIFICATE_PASSWORD:-}" ]; then
  log_info "Setting up certificate..."
  echo $CM_CERTIFICATE | base64 --decode > /tmp/certificate.p12
  
  if command -v keychain &>/dev/null; then
    keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password $CM_CERTIFICATE_PASSWORD
    log_success "✅ Certificate added to keychain"
  else
    log_warn "⚠️ keychain command not available, trying alternative certificate import..."
    # Try using security command as alternative
    if security import /tmp/certificate.p12 -k ~/Library/Keychains/login.keychain-db -P "$CM_CERTIFICATE_PASSWORD" 2>/dev/null; then
      log_success "✅ Certificate imported using security command"
    else
      log_warn "⚠️ Could not import certificate (continuing with existing keychain)"
    fi
  fi
else
  log_warn "⚠️ Certificate not provided, using existing keychain"
fi

# Validate signing identity
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "$CM_DISTRIBUTION_TYPE" || echo "0")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
  log_error "❌ No valid $CM_DISTRIBUTION_TYPE signing identities found in keychain"
  exit 1
else
  log_success "✅ Found $IDENTITY_COUNT valid $CM_DISTRIBUTION_TYPE identity(ies) in keychain"
fi

# =============================================================================
# PHASE 4: DART/FLUTTER SETUP
# =============================================================================

echo "📱 Phase 4: Dart/Flutter setup..."

# Fix missing files if needed
log_info "🔧 Checking for missing Dart files..."
if [ -f "lib/scripts/ios/fix_missing_files.sh" ]; then
  chmod +x lib/scripts/ios/fix_missing_files.sh
  if ./lib/scripts/ios/fix_missing_files.sh; then
    log_success "✅ Missing files fix completed"
  else
    log_warn "⚠️ Missing files fix had issues, continuing..."
  fi
fi

# Fix preprocessor directive issues if needed
log_info "🔧 Checking for preprocessor directive issues..."
if [ -f "lib/scripts/ios/fix_preprocessor_directive.sh" ]; then
  chmod +x lib/scripts/ios/fix_preprocessor_directive.sh
  if ./lib/scripts/ios/fix_preprocessor_directive.sh; then
    log_success "✅ Preprocessor directive fix completed"
  else
    log_warn "⚠️ Preprocessor directive fix had issues, continuing..."
  fi
fi

# Install Flutter dependencies
log_info "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

# Check if Runner.xcworkspace exists
if [ ! -d "ios/Runner.xcworkspace" ]; then
  log_error "❌ Runner.xcworkspace not found"
  log_info "📋 Creating iOS project..."
  flutter create --platforms=ios .
fi

# Check if Flutter generated files exist
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  log_error "❌ ios/Flutter/Generated.xcconfig not found"
  log_info "📋 Running flutter pub get..."
  flutter pub get
fi

# =============================================================================
# PHASE 5: BUNDLE IDENTIFIER UPDATE
# =============================================================================

echo "🆔 Phase 5: Bundle identifier update..."

OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="$BUNDLE_ID"

# Update in project.pbxproj
find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in Info.plist
find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in entitlements files
find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

log_success "✅ Bundle Identifier updated to $NEW_BUNDLE_ID"

# =============================================================================
# PHASE 6: COCOAPODS SETUP
# =============================================================================

echo "📦 Phase 6: CocoaPods setup..."

# Backup and remove Podfile.lock if it exists
if [ -f "ios/Podfile.lock" ]; then
  cp ios/Podfile.lock ios/Podfile.lock.backup
  log_info "🗂️ Backed up Podfile.lock to Podfile.lock.backup"
  rm ios/Podfile.lock
  log_info "🗑️ Removed original Podfile.lock"
fi

if ! command -v pod &>/dev/null; then
  log_error "❌ CocoaPods is not installed!"
  log_info "📋 To install CocoaPods, run one of these commands:"
  log_info "   sudo gem install cocoapods"
  log_info "   brew install cocoapods"
  log_info "   Or visit: https://cocoapods.org/#install"
  log_info "📋 After installation, run this script again."
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

log_success "✅ CocoaPods setup completed"

# =============================================================================
# PHASE 7: XCODE CONFIGURATION
# =============================================================================

echo "⚙️ Phase 7: Xcode configuration..."

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
if command -v xcode-project &>/dev/null; then
  xcode-project use-profiles
  log_success "✅ Xcode project settings updated"
else
  log_warn "⚠️ xcode-project command not available (continuing without updating Xcode project settings)"
  log_info "📋 This is normal in some CI/CD environments"
fi

# =============================================================================
# PHASE 8: FLUTTER BUILD
# =============================================================================

echo "📱 Phase 8: Flutter build..."

log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE" \
  2>&1 | tee flutter_build.log | grep -E "(Building|Error|FAILURE|warning|Warning|error|Exception|\.dart)"

# =============================================================================
# PHASE 9: XCODE ARCHIVE
# =============================================================================

echo "📦 Phase 9: Xcode archive..."

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
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  2>&1 | tee xcodebuild_archive.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

# =============================================================================
# PHASE 10: IPA EXPORT
# =============================================================================

echo "📤 Phase 10: IPA export..."

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
        <key>$BUNDLE_ID</key>
        <string>$UUID</string>
      </dict>
  <key>signingCertificate</key>
  	<string>$CM_DISTRIBUTION_TYPE</string>
  <key>signingStyle</key>
    <string>$CODE_SIGNING_STYLE</string>
  <key>teamID</key>
    <string>$APPLE_TEAM_ID</string>
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
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/output \
  -exportOptionsPlist ios/ExportOptions.plist

# =============================================================================
# PHASE 11: IPA VERIFICATION AND UPLOAD
# =============================================================================

echo "✅ Phase 11: IPA verification and upload..."

# Find and verify IPA
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
  log_error "❌ IPA file not found in build/ios/output. Searching entire directory..."
  IPA_PATH=$(find . -name "*.ipa" | head -n 1)
fi

if [ -z "$IPA_PATH" ]; then
  log_error "❌ IPA file not found. Build failed."
  exit 1
fi

log_success "✅ IPA found at: $IPA_PATH"
log_info "📏 IPA file size: $(du -h "$IPA_PATH" | cut -f1)"

# Upload to App Store Connect if credentials are available
if [ ! -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] && [ ! -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
  log_info "📤 Uploading to App Store Connect..."
  
  # Download API key if URL is provided
  if [ ! -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
    APP_STORE_CONNECT_API_KEY_PATH_New="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
    mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH_New")"
    curl -fSL "$APP_STORE_CONNECT_API_KEY_PATH" -o "$APP_STORE_CONNECT_API_KEY_PATH_New"
    log_success "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH_New"
  fi
  
  xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
  
  log_success "✅ Upload to App Store Connect completed"
else
  log_warn "⚠️ App Store Connect credentials not provided, skipping upload"
fi

# =============================================================================
# PHASE 12: CLEANUP AND FINALIZATION
# =============================================================================

echo "🧹 Phase 12: Cleanup and finalization..."

# Clean up temporary files
rm -f /tmp/profile.plist
rm -f /tmp/certificate.p12
rm -f ios/ExportOptions.plist

# Create project backup
log_info "📦 Creating project backup..."
zip -r project_backup.zip . -x "build/*" ".dart_tool/*" ".git/*" "output/*" "*.log" > /dev/null 2>&1 || log_warn "⚠️ Backup creation failed"

# List build artifacts
log_info "📋 Build artifacts:"
if [ -d "build/ios/output" ]; then
  ls -la build/ios/output/
fi

if [ -d "build/ios/archive" ]; then
  ls -la build/ios/archive/
fi

log_success "🎉 Simple iOS Build Workflow completed successfully!"
log_info "📱 IPA Location: $IPA_PATH"
log_info "📦 Archive Location: build/ios/archive/Runner.xcarchive"
log_info "📋 Build Logs: flutter_build.log, xcodebuild_archive.log" 