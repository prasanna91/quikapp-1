#!/bin/bash

# iOS Workflow Build Script - Simple Version with email notifications
# Direct build without complex validation

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🏗️ Starting iOS Workflow Build..."

# Make scripts executable
chmod +x lib/scripts/ios/*.sh
chmod +x lib/scripts/utils/*.sh

# Simple build process
log_info "📱 Building iOS app..."

if ./lib/scripts/ios/simple_build.sh; then
  log_success "✅ Build completed successfully!"
  
           # Send success email notification
         if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
           log_info "📧 Sending build success notification..."
           if [ -f "lib/scripts/utils/send_email.sh" ]; then
             chmod +x lib/scripts/utils/send_email.sh
             ./lib/scripts/utils/send_email.sh \
               "build_success" \
               "ios" \
               "${CM_BUILD_ID:-unknown}"
           fi
         fi
else
  log_error "❌ Build failed"
  
           # Send failure email notification
         if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
           log_info "📧 Sending build failure notification..."
           if [ -f "lib/scripts/utils/send_email.sh" ]; then
             chmod +x lib/scripts/utils/send_email.sh
             ./lib/scripts/utils/send_email.sh \
               "build_failed" \
               "ios" \
               "${CM_BUILD_ID:-unknown}" \
               "Build failed during iOS app compilation or IPA export process"
           fi
         fi
  
  exit 1
fi

log_success "✅ iOS Workflow Build completed" 