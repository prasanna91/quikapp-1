#!/bin/bash

# Simple iOS Pre-Build Script - With permissions and email notifications

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }
log()         { echo "📌 $1"; }

echo "🚀 Starting Simple iOS Pre-Build with permissions and notifications..."

# Validate environment variables first
log_info "🔍 Validating environment variables..."
if [ -f "lib/scripts/ios-workflow/validate_environment.sh" ]; then
  chmod +x lib/scripts/ios-workflow/validate_environment.sh
  if ./lib/scripts/ios-workflow/validate_environment.sh; then
    log_success "✅ Environment validation passed"
  else
    log_error "❌ Environment validation failed"
    exit 1
  fi
else
  log_warn "⚠️ Environment validation script not found, skipping..."
fi

# Send email notification for build start
if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
  log_info "📧 Sending build start notification..."
  if [ -f "lib/scripts/utils/send_email.sh" ]; then
    chmod +x lib/scripts/utils/send_email.sh
    ./lib/scripts/utils/send_email.sh \
      "build_started" \
      "ios" \
      "${CM_BUILD_ID:-unknown}"
  fi
fi

# Run comprehensive iOS workflow fix
log_info "🔧 Running comprehensive iOS workflow fix..."
if [ -f "lib/scripts/ios-workflow/fix_workflow_issues.sh" ]; then
  chmod +x lib/scripts/ios-workflow/fix_workflow_issues.sh
  if ./lib/scripts/ios-workflow/fix_workflow_issues.sh; then
    log_success "✅ iOS workflow issues fixed successfully"
  else
    log_error "❌ iOS workflow fix failed"
    exit 1
  fi
else
  log_warn "⚠️ iOS workflow fix script not found, running basic setup..."
  
  # Basic setup as fallback
  log_info "🧹 Cleaning previous builds..."
  flutter clean
  rm -rf ios/build/
  rm -rf ios/Pods/
  
  log_info "📦 Installing Flutter dependencies..."
  flutter pub get
  
  log_info "📦 Installing CocoaPods..."
  if [ -f "ios/Podfile" ]; then
    cd ios
    if pod install; then
      log_success "✅ CocoaPods installed successfully"
    else
      log_error "❌ CocoaPods installation failed"
      cd ..
      exit 1
    fi
    cd ..
  else
    log_error "❌ Podfile not found in ios directory"
    exit 1
  fi
fi

# Inject permissions if script exists
log_info "🔐 Injecting permissions..."
if [ -f "lib/scripts/ios/inject_permissions.sh" ]; then
  chmod +x lib/scripts/ios/inject_permissions.sh
  if ./lib/scripts/ios/inject_permissions.sh; then
    log_success "✅ Permissions injected successfully"
  else
    log_error "❌ Permissions injection failed"
    exit 1
  fi
else
  log_warn "⚠️ Permissions script not found, skipping..."
fi

# Inject Info.plist values if script exists
log_info "📱 Injecting Info.plist values..."
if [ -f "lib/scripts/ios/inject_info_plist.sh" ]; then
  chmod +x lib/scripts/ios/inject_info_plist.sh
  if ./lib/scripts/ios/inject_info_plist.sh; then
    log_success "✅ Info.plist injection completed"
  else
    log_error "❌ Info.plist injection failed"
    exit 1
  fi
else
  log_warn "⚠️ Info.plist injection script not found, skipping..."
fi

# Conditional Firebase injection if script exists
log_info "🔥 Conditional Firebase injection..."
if [ -f "lib/scripts/ios/conditional_firebase_injection.sh" ]; then
  chmod +x lib/scripts/ios/conditional_firebase_injection.sh
  if ./lib/scripts/ios/conditional_firebase_injection.sh; then
    log_success "✅ Firebase injection completed"
  else
    log_error "❌ Firebase injection failed"
    exit 1
  fi
else
  log_warn "⚠️ Firebase injection script not found, skipping..."
fi

log_success "✅ Pre-build completed" 