#!/bin/bash

# TestFlight Upload Script - Following akash_build.sh method

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "📤 Uploading to TestFlight using akash_build.sh method..."

# Check if IPA exists
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
  echo "IPA not found in build/ios/output. Searching entire clone directory..."
  IPA_PATH=$(find /Users/builder/clone -name "*.ipa" | head -n 1)
fi
if [ -z "$IPA_PATH" ]; then
  log_error "❌ IPA file not found. Aborting upload."
  exit 1
fi
log_success "✅ IPA found at: $IPA_PATH"

# Setup App Store Connect API key
APP_STORE_CONNECT_API_KEY_PATH_New="$HOME/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER}.p8"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$APP_STORE_CONNECT_API_KEY_PATH_New")"

# Download the .p8 file into a supported directory
if [ -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]; then
  curl -fSL "$APP_STORE_CONNECT_API_KEY_PATH" -o "$APP_STORE_CONNECT_API_KEY_PATH_New"
  log_success "✅ API key downloaded to $APP_STORE_CONNECT_API_KEY_PATH_New"
else
  log_error "❌ APP_STORE_CONNECT_API_KEY_PATH is not set"
  exit 1
fi

# Upload to TestFlight using xcrun altool with API key
log_info "📤 Uploading IPA to TestFlight..."
xcrun altool --upload-app \
  -f "$IPA_PATH" \
  -t ios \
  --apiKey "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
  --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"

log_success "✅ TestFlight upload completed" 