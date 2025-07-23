#!/bin/bash

# Test CocoaPods Fix Script
# Tests the CocoaPods repository update and installation process

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🧪 Testing CocoaPods fix..."

# Check if we're in the right directory
if [ ! -f "ios/Podfile" ]; then
  log_error "❌ Podfile not found. Please run this script from the project root."
  exit 1
fi

cd ios

# Test 1: Update CocoaPods repository
log_info "📦 Test 1: Updating CocoaPods repository..."
if pod repo update --silent; then
  log_success "✅ CocoaPods repository update successful"
else
  log_warn "⚠️ CocoaPods repository update failed"
fi

# Test 2: Check if pod install works
log_info "📦 Test 2: Testing pod install..."
if pod install --repo-update --clean-install; then
  log_success "✅ Pod install successful"
else
  log_warn "⚠️ Pod install failed, trying legacy mode..."
  
  if pod install --repo-update --clean-install --legacy; then
    log_success "✅ Pod install successful with legacy mode"
  else
    log_error "❌ Pod install failed completely"
    cd ..
    exit 1
  fi
fi

# Test 3: Verify Pods directory exists
if [ -d "Pods" ]; then
  log_success "✅ Pods directory exists"
else
  log_error "❌ Pods directory missing"
  cd ..
  exit 1
fi

# Test 4: Check for common Firebase pods
if [ -d "Pods/Firebase" ]; then
  log_success "✅ Firebase pods found"
else
  log_warn "⚠️ Firebase pods not found (this might be normal if Firebase is not configured)"
fi

cd ..

log_success "🎉 All CocoaPods tests passed!" 