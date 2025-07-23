#!/bin/bash

# Production iOS Build Script
# Optimized for reliable production builds

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }

echo "🏭 Starting Production iOS Build..."

# Environment validation
if [ -z "${APPLE_TEAM_ID:-}" ]; then
  log_error "❌ APPLE_TEAM_ID not set"
  exit 1
fi

if [ -z "${CM_PROVISIONING_PROFILE:-}" ]; then
  log_error "❌ CM_PROVISIONING_PROFILE not set"
  exit 1
fi

# Run comprehensive fix
if [ -f "lib/scripts/ios/comprehensive_ios_fix.sh" ]; then
  chmod +x lib/scripts/ios/comprehensive_ios_fix.sh
  ./lib/scripts/ios/comprehensive_ios_fix.sh
fi

# Build with enhanced error handling
if [ -f "lib/scripts/ios/enhanced_build.sh" ]; then
  chmod +x lib/scripts/ios/enhanced_build.sh
  ./lib/scripts/ios/enhanced_build.sh
else
  log_error "❌ Enhanced build script not found"
  exit 1
fi

log_success "🎉 Production build completed successfully!"
