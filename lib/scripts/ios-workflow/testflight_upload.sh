#!/bin/bash

# TestFlight Upload Script
# Handles TestFlight uploads with better error handling (no auto-incrementing)

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "📤 Starting TestFlight Upload..."

# Check if IPA exists
IPA_PATH="build/ios/output/sample_project.ipa"
if [ ! -f "$IPA_PATH" ]; then
  log_error "❌ IPA not found at $IPA_PATH"
  log_info "📋 Please run the build script first"
  exit 1
fi

log_success "✅ IPA found at: $IPA_PATH"

# Check current version
if [ -f "pubspec.yaml" ]; then
  CURRENT_VERSION=$(grep "version:" pubspec.yaml | head -1 | sed 's/version: //' | tr -d ' ')
  log_info "📋 Current version: $CURRENT_VERSION"
else
  log_warn "⚠️ pubspec.yaml not found, cannot determine version"
fi

# Check App Store Connect credentials
if [ -z "${APP_STORE_CONNECT_KEY_IDENTIFIER:-}" ] || [ -z "${APP_STORE_CONNECT_ISSUER_ID:-}" ]; then
  log_error "❌ App Store Connect credentials not set"
  log_info "📋 Please set APP_STORE_CONNECT_KEY_IDENTIFIER and APP_STORE_CONNECT_ISSUER_ID"
  exit 1
fi

# Download API key if URL is provided
if [ ! -z "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
  log_info "📥 Downloading API key..."
  mkdir -p /Users/builder/private_keys
  curl -L "$APP_STORE_CONNECT_API_KEY_PATH" -o "/Users/builder/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
  log_success "✅ API key downloaded to /Users/builder/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"
fi

# Upload to TestFlight
log_info "📤 Uploading IPA to TestFlight..."

# Use altool for upload
ALTOOL_PATH="/Applications/Xcode-16.0.app/Contents/SharedFrameworks/ContentDeliveryServices.framework/Frameworks/AppStoreService.framework/Support/altool"

if [ ! -f "$ALTOOL_PATH" ]; then
  log_error "❌ altool not found at $ALTOOL_PATH"
  exit 1
fi

# Upload with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  log_info "📤 Upload attempt $((RETRY_COUNT + 1))/$MAX_RETRIES..."
  
  if "$ALTOOL_PATH" --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
    --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
    --verbose 2>&1 | tee testflight_upload.log; then
    
    log_success "✅ TestFlight upload completed successfully!"
    exit 0
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Check if it's a version conflict
    if grep -q "bundle version must be higher" testflight_upload.log 2>/dev/null; then
      log_error "❌ Version conflict detected!"
      log_info "📋 The bundle version has already been used in TestFlight"
      log_info "📋 Current version: $CURRENT_VERSION"
      log_info "📋 Solution: Please increment the version in pubspec.yaml and rebuild"
      log_info "📋 Example: Change version: 1.0.0+61 to version: 1.0.0+62"
      exit 1
    elif [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      log_warn "⚠️ Upload failed, retrying in 5 seconds..."
      sleep 5
    else
      log_error "❌ TestFlight upload failed after $MAX_RETRIES attempts"
      log_info "📋 Check testflight_upload.log for details"
      exit 1
    fi
  fi
done 