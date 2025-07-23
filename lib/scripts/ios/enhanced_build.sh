#!/bin/bash

# Enhanced iOS Build Script with Better Error Handling
# Provides detailed error information and debugging

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🚀 Starting Enhanced iOS Build with Detailed Error Handling..."

# Function to check environment variables
check_environment() {
  log_info "🔍 Checking environment variables..."
  
  REQUIRED_VARS=("APPLE_TEAM_ID" "CM_PROVISIONING_PROFILE" "CM_CERTIFICATE" "CM_CERTIFICATE_PASSWORD")
  MISSING_VARS=()
  
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_VARS+=("$var")
    fi
  done
  
  if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_warn "⚠️ Missing environment variables: ${MISSING_VARS[*]}"
    log_info "📋 This might cause build issues, but continuing..."
  else
    log_success "✅ All required environment variables are set"
  fi
}

# Function to check Flutter setup
check_flutter_setup() {
  log_info "🔍 Checking Flutter setup..."
  
  if ! command -v flutter &>/dev/null; then
    log_error "❌ Flutter is not installed or not in PATH"
    exit 1
  fi
  
  log_info "📱 Flutter version: $(flutter --version | head -1)"
  
  # Check if we're in a Flutter project
  if [ ! -f "pubspec.yaml" ]; then
    log_error "❌ Not in a Flutter project directory"
    exit 1
  fi
  
  log_success "✅ Flutter setup verified"
}

# Function to check iOS project setup
check_ios_setup() {
  log_info "🔍 Checking iOS project setup..."
  
  if [ ! -d "ios" ]; then
    log_error "❌ iOS directory not found"
    exit 1
  fi
  
  if [ ! -f "ios/Podfile" ]; then
    log_error "❌ Podfile not found"
    exit 1
  fi
  
  if [ ! -d "ios/Runner.xcworkspace" ]; then
    log_error "❌ Runner.xcworkspace not found"
    exit 1
  fi
  
  log_success "✅ iOS project setup verified"
}

# Function to run Flutter build with detailed error handling
run_flutter_build() {
  log_info "📱 Building Flutter iOS app in release mode..."
  
  # Create build log file
  BUILD_LOG="flutter_build_$(date +%Y%m%d_%H%M%S).log"
  
  # Run Flutter build with full output
  if flutter build ios --release --no-codesign \
    --build-name="${VERSION_NAME:-1.0.0}" \
    --build-number="${VERSION_CODE:-1}" \
    2>&1 | tee "$BUILD_LOG"; then
    log_success "✅ Flutter build completed successfully"
  else
    log_error "❌ Flutter build failed"
    log_error "📋 Build log saved to: $BUILD_LOG"
    log_error "📋 Last 50 lines of build log:"
    tail -50 "$BUILD_LOG"
    exit 1
  fi
}

# Function to run Xcode archive with detailed error handling
run_xcode_archive() {
  log_info "📦 Archiving app with Xcode..."
  
  # Create archive log file
  ARCHIVE_LOG="xcodebuild_archive_$(date +%Y%m%d_%H%M%S).log"
  
  # Create archive directory
  mkdir -p build/ios/archive
  
  # Run Xcode archive with full output
  if xcodebuild -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -archivePath build/ios/archive/Runner.xcarchive \
    -destination 'generic/platform=iOS' \
    archive \
    DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}" \
    2>&1 | tee "$ARCHIVE_LOG"; then
    log_success "✅ Xcode archive completed successfully"
  else
    log_error "❌ Xcode archive failed"
    log_error "📋 Archive log saved to: $ARCHIVE_LOG"
    log_error "📋 Last 50 lines of archive log:"
    tail -50 "$ARCHIVE_LOG"
    exit 1
  fi
}

# Function to export IPA with detailed error handling
run_ipa_export() {
  log_info "📤 Exporting IPA..."
  
  # Create export log file
  EXPORT_LOG="xcodebuild_export_$(date +%Y%m%d_%H%M%S).log"
  
  # Create output directory
  OUTPUT_DIR="${OUTPUT_DIR:-build/ios/output}"
  mkdir -p "$OUTPUT_DIR"
  
  # Create ExportOptions.plist
  log_info "🛠️ Creating ExportOptions.plist..."
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
      <key>${BUNDLE_ID:-com.garbcode.garbcodeapp}</key>
      <string>${PROFILE_SPECIFIER_UUID:-$(uuidgen)}</string>
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
  
  # Run Xcode export with full output
  if xcodebuild -exportArchive \
    -archivePath build/ios/archive/Runner.xcarchive \
    -exportPath "$OUTPUT_DIR" \
    -exportOptionsPlist ios/ExportOptions.plist \
    2>&1 | tee "$EXPORT_LOG"; then
    log_success "✅ IPA export completed successfully"
  else
    log_error "❌ IPA export failed"
    log_error "📋 Export log saved to: $EXPORT_LOG"
    log_error "📋 Last 50 lines of export log:"
    tail -50 "$EXPORT_LOG"
    exit 1
  fi
  
  # Find and rename IPA
  IPA_PATH=$(find "$OUTPUT_DIR" -name "*.ipa" -type f | head -n 1)
  
  if [ -f "$IPA_PATH" ]; then
    mv "$IPA_PATH" "$OUTPUT_DIR/Runner.ipa"
    log_success "✅ IPA created: $OUTPUT_DIR/Runner.ipa"
  else
    log_error "❌ IPA file not found. Export may have failed."
    exit 1
  fi
}

# Main execution
echo "🔧 Running comprehensive build checks..."

# Check environment and setup
check_environment
check_flutter_setup
check_ios_setup

# Run the build process
run_flutter_build
run_xcode_archive
run_ipa_export

log_success "🎉 Enhanced iOS build process completed successfully!" 