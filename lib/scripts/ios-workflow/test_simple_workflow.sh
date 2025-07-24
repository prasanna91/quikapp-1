#!/bin/bash

# Test Simple iOS Workflow
# Tests the simplified iOS workflow

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🧪 Testing Simple iOS Workflow..."

# Check if scripts exist
REQUIRED_SCRIPTS=(
  "lib/scripts/ios-workflow/pre-build.sh"
  "lib/scripts/ios-workflow/build.sh"
  "lib/scripts/ios-workflow/post-build.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    log_success "✅ $script exists"
  else
    log_error "❌ $script missing"
    exit 1
  fi
done

# Check if scripts are executable
for script in "${REQUIRED_SCRIPTS[@]}"; do
  if [ -x "$script" ]; then
    log_success "✅ $script is executable"
  else
    log_error "❌ $script is not executable"
    exit 1
  fi
done

# Check Flutter setup
log_info "🔍 Checking Flutter setup..."
if command -v flutter &>/dev/null; then
  log_success "✅ Flutter is installed"
  log_info "Flutter version: $(flutter --version | head -1)"
else
  log_error "❌ Flutter is not installed"
  exit 1
fi

# Check Xcode setup
log_info "🔍 Checking Xcode setup..."
if command -v xcodebuild &>/dev/null; then
  log_success "✅ Xcode is installed"
  log_info "Xcode version: $(xcodebuild -version | head -1)"
else
  log_error "❌ Xcode is not installed"
  exit 1
fi

# Check CocoaPods setup
log_info "🔍 Checking CocoaPods setup..."
if command -v pod &>/dev/null; then
  log_success "✅ CocoaPods is installed"
  log_info "CocoaPods version: $(pod --version)"
else
  log_error "❌ CocoaPods is not installed"
  exit 1
fi

# Check project structure
log_info "🔍 Checking project structure..."
if [ -f "pubspec.yaml" ]; then
  log_success "✅ pubspec.yaml exists"
else
  log_error "❌ pubspec.yaml not found"
  exit 1
fi

if [ -d "ios" ]; then
  log_success "✅ ios directory exists"
else
  log_warn "⚠️ ios directory not found (will be created during build)"
fi

# Check environment variables (optional)
log_info "🔍 Checking environment variables..."
REQUIRED_VARS=(
  "APPLE_TEAM_ID"
  "CM_PROVISIONING_PROFILE"
  "CM_CERTIFICATE"
  "CM_CERTIFICATE_PASSWORD"
  "VERSION_NAME"
  "VERSION_CODE"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [ ! -z "${!var:-}" ]; then
    log_success "✅ $var is set"
  else
    log_warn "⚠️ $var is not set (will be required during build)"
  fi
done

log_success "🎉 Simple iOS Workflow test completed successfully!"
log_info "📋 The workflow is ready to use:"
log_info "   ./lib/scripts/ios-workflow/pre-build.sh"
log_info "   ./lib/scripts/ios-workflow/build.sh"
log_info "   ./lib/scripts/ios-workflow/post-build.sh" 