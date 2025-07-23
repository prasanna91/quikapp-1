#!/bin/bash

# iOS Ad Hoc Pre-Build Script
# Handles pre-build setup for ios-adhoc workflow

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }


echo "🚀 Starting iOS Akash Pre-Build Setup..."
echo "📊 Build Environment:"
echo "  - Flutter: $(flutter --version | head -1)"
echo "  - Java: $(java -version 2>&1 | head -1)"
echo "  - Xcode: $(xcodebuild -version | head -1)"
echo "  - CocoaPods: $(pod --version)"
echo "  - Memory: $(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"

# Pre-build cleanup and optimization
echo "🧹 Pre-build cleanup..."

flutter clean > /dev/null 2>&1 || {
  log_warn "⚠️ flutter clean failed (continuing)"
}

rm -rf ~/Library/Developer/Xcode/DerivedData/* > /dev/null 2>&1 || true
rm -rf .dart_tool/ > /dev/null 2>&1 || true
rm -rf ios/Pods/ > /dev/null 2>&1 || true
rm -rf ios/build/ > /dev/null 2>&1 || true
rm -rf ios/.symlinks > /dev/null 2>&1 || true

echo "Initialize keychain to be used for codesigning using Codemagic CLI 'keychain' command"
keychain initialize

log_info "Setting up provisioning profile..."

#PROFILE_Specifier_UUID=$(uuidgen)
PROFILE_Specifier_UUID="$PROFILE_SPECIFIER_UUID_AKASH"
CM_PROVISIONING_PROFILE="$CM_PROVISIONING_PROFILE_AKASH"
      PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
      mkdir -p "$PROFILES_HOME"
      PROFILE_PATH="$PROFILES_HOME/$PROFILE_Specifier_UUID.mobileprovision"
      echo ${CM_PROVISIONING_PROFILE} | base64 --decode > "$PROFILE_PATH"
      echo "Saved provisioning profile $PROFILE_PATH"

# Extract the embedded plist from the provisioning profile
security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist

# Extract UUID
UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist)
# Extract Bundle Identifier (assuming it's the first in the Entitlements dictionary)
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist | cut -d '.' -f 2-)

if [[ -z "$UUID" ]]; then
  echo "❌ Missing required variable: UUID"
  exit 1
fi

if [[ -z "$BUNDLE_ID" ]]; then
  echo "❌ Missing required variable: BUNDLE_ID"
  exit 1
fi

echo "UUID: $UUID"
echo "Bundle Identifier: $BUNDLE_ID"

CM_CERTIFICATE="$CM_CERTIFICATE_AKASH"
CM_CERTIFICATE_PASSWORD="$CM_CERTIFICATE_PASSWORD_AKASH"
echo $CM_CERTIFICATE | base64 --decode > /tmp/certificate.p12
keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password $CM_CERTIFICATE_PASSWORD

# Validate that a valid Apple Distribution identity is available in the keychain
IDENTITY_COUNT=$(security find-identity -v -p codesigning | grep -c "$CM_DISTRIBUTION_TYPE_AKASH")
if [[ "$IDENTITY_COUNT" -eq 0 ]]; then
  echo "❌ No valid $CM_DISTRIBUTION_TYPE_AKASH signing identities found in keychain. Exiting build."
  exit 1
else
  echo "✅ Found $IDENTITY_COUNT valid $CM_DISTRIBUTION_TYPE_AKASH identity(ies) in keychain."
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

#Now Need to update display name
PLIST_PATH="ios/Runner/Info.plist"
DISPLAY_NAME="$APP_DISPLAY_NAME_AKASH"

# Check if key exists, else add it
/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null \
  && /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$DISPLAY_NAME'" "$PLIST_PATH" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$DISPLAY_NAME'" "$PLIST_PATH"

# Now Need to replace bundle identifier.
OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="$BUNDLE_ID"

# Update in project.pbxproj
find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in Info.plist (just in case it’s hardcoded)
find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Update in any entitlements files
find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \;

# Optional: Print confirmation
echo "✅ Bundle Identifier updated to $NEW_BUNDLE_ID"

# Install Flutter dependencies (including rename package)
echo "📦 Installing Flutter dependencies..."
flutter pub get > /dev/null || {
  log_error "flutter pub get failed"
  exit 1
}

run_cocoapods_commands

#If remove this then update teh Release.xcconfig also.
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
  echo "CODE_SIGN_STYLE = $CODE_SIGNING_STYLE_AKASH"
  echo "DEVELOPMENT_TEAM = $APPLE_TEAM_ID"
  echo "PROVISIONING_PROFILE_SPECIFIER = $UUID"
  echo "CODE_SIGN_IDENTITY = $CM_DISTRIBUTION_TYPE_AKASH"
  echo "PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID"
} >> "$XC_CONFIG_PATH"

echo "✅ release.xcconfig updated:"
cat "$XC_CONFIG_PATH"

echo "Set up code signing settings on Xcode project"
xcode-project use-profiles

zip -r project_backup.zip . -x "build/*" ".dart_tool/*" ".git/*" "output/*"

#temporary set to release permanenlty
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE" \
  2>&1 | tee flutter_build.log | grep -E "(Building|Error|FAILURE|warning|Warning|error|Exception|\.dart)"

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
  	<string>$CM_DISTRIBUTION_TYPE_AKASH</string>
  <key>signingStyle</key>
    <string>$CODE_SIGNING_STYLE_EXPORT_AKASH</string>
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

log_info "📤 Exporting IPA..."

set -x # verbose shell output

xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/output \
  -exportOptionsPlist ios/ExportOptions.plist

#Issue here. Due to last line.
#xcodebuild -exportArchive \
#  -archivePath build/ios/archive/Runner.xcarchive \
#  -exportPath build/ios/output \
#  -exportOptionsPlist ios/ExportOptions.plist \
#  2>&1 | tee xcodebuild_export.log | grep -E "(error:|warning:|Check dependencies|Provisioning|CodeSign|FAILED|Succeeded)"

APP_STORE_CONNECT_API_KEY_PATH_New="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH_New")"

# Download the .p8 file into a supported directory
curl -fSL "$APP_STORE_CONNECT_API_KEY_PATH_AKASH" -o "$APP_STORE_CONNECT_API_KEY_PATH_New"
echo "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH_New"

        IPA_PATH=$(find /Users/builder/clone/build/ios/output -name "*.ipa" | head -n 1)
        if [ -z "$IPA_PATH" ]; then
          echo "IPA not found in build/ios/output. Searching entire clone directory..."
          IPA_PATH=$(find /Users/builder/clone -name "*.ipa" | head -n 1)
        fi
        if [ -z "$IPA_PATH" ]; then
          echo "❌ IPA file not found. Aborting upload."
          exit 1
        fi
        echo "✅ IPA found at: $IPA_PATH"

xcrun altool --upload-app \
  -f "$IPA_PATH" \
  -t ios \
  --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

log_success "🎉 iOS build process completed successfully!"