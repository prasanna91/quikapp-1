#!/bin/bash

# iOS Workflow Post-Build Script
# Simple post-build cleanup and notifications

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🚀 Starting iOS Workflow Post-Build..."

# Clean up temporary files
log_info "🧹 Cleaning up temporary files..."
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

# Check for IPA file
IPA_PATH=$(find . -name "*.ipa" | head -n 1)
if [ ! -z "$IPA_PATH" ]; then
  log_success "✅ IPA file found: $IPA_PATH"
  log_info "📏 IPA file size: $(du -h "$IPA_PATH" | cut -f1)"
else
  log_warn "⚠️ No IPA file found"
fi

log_success "🎉 iOS Post-Build completed successfully!" 