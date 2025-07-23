#!/bin/bash

# iOS Workflow Build Script - Enhanced Version with Better Error Handling
# Uses enhanced build script with detailed error information

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🏗️ Starting Enhanced iOS Workflow Build..."

# Make scripts executable
chmod +x lib/scripts/ios/*.sh
chmod +x lib/scripts/utils/*.sh

# Run comprehensive iOS fix first
log_info "🔧 Running comprehensive iOS fix..."
if [ -f "lib/scripts/ios/comprehensive_ios_fix.sh" ]; then
  chmod +x lib/scripts/ios/comprehensive_ios_fix.sh
  if ./lib/scripts/ios/comprehensive_ios_fix.sh; then
    log_success "✅ Comprehensive iOS fix completed"
  else
    log_warn "⚠️ Comprehensive iOS fix had issues, continuing with build..."
  fi
fi

# Run diagnostics if build fails
run_diagnostics() {
  log_info "🔍 Running build diagnostics..."
  if [ -f "lib/scripts/ios/diagnose_build_issues.sh" ]; then
    chmod +x lib/scripts/ios/diagnose_build_issues.sh
    ./lib/scripts/ios/diagnose_build_issues.sh
  fi
}

# Enhanced build process
log_info "📱 Building iOS app with enhanced error handling..."

# Try enhanced build script first
if [ -f "lib/scripts/ios/enhanced_build.sh" ]; then
  chmod +x lib/scripts/ios/enhanced_build.sh
  if ./lib/scripts/ios/enhanced_build.sh; then
    log_success "✅ Enhanced build completed successfully!"
    
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
    log_error "❌ Enhanced build failed"
    run_diagnostics
    
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
else
  # Fallback to simple build script
  log_warn "⚠️ Enhanced build script not found, using simple build..."
  if ./lib/scripts/ios/simple_build.sh; then
    log_success "✅ Simple build completed successfully!"
    
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
    log_error "❌ Simple build failed"
    run_diagnostics
    
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
fi

log_success "✅ Enhanced iOS Workflow Build completed" 