#!/bin/bash

# iOS Workflow Build Script
# Simple and direct build process

set -euo pipefail
trap 'echo "❌ Error occurred at line $LINENO. Exit code: $?" >&2; exit 1' ERR

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🚀 Starting iOS Workflow Build..."

# Fix preprocessor directive issue if it exists
log_info "🔧 Checking for preprocessor directive issues..."
if [ -f "lib/scripts/ios/fix_preprocessor_directive.sh" ]; then
  chmod +x lib/scripts/ios/fix_preprocessor_directive.sh
  if ./lib/scripts/ios/fix_preprocessor_directive.sh; then
    log_success "✅ Preprocessor directive fix completed"
  else
    log_warn "⚠️ Preprocessor directive fix had issues, continuing..."
  fi
fi

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

# Build Flutter app
log_info "📱 Building Flutter iOS app in release mode..."
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" \
  --build-number="$VERSION_CODE" \
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
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
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

# Find and upload IPA
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

log_success "🎉 iOS build process completed successfully!" 