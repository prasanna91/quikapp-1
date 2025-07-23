#!/bin/bash

# Simple iOS Post-Build Script - Following akash_build.sh method

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🛡️ Post-build validation..."

# Check for IPA file in build/ios/output (akash_build.sh location)
IPA_PATH=$(find build/ios/output -name "*.ipa" | head -n 1)
if [ -z "$IPA_PATH" ]; then
  echo "IPA not found in build/ios/output. Searching entire clone directory..."
  IPA_PATH=$(find /Users/builder/clone -name "*.ipa" | head -n 1)
fi

if [ -n "$IPA_PATH" ]; then
  log_success "✅ IPA file found: $IPA_PATH"
  ls -la "$IPA_PATH"
else
  log_error "❌ IPA file not found"
  exit 1
fi

log_success "✅ Post-build completed" 