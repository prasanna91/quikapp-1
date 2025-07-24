#!/bin/bash

# Test Simple iOS Workflow Script
# Verifies the readiness of the simple iOS workflow

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🧪 Testing Simple iOS Workflow..."

# Check if simple_ios_build.sh exists
if [ ! -f "lib/scripts/ios-workflow/simple_ios_build.sh" ]; then
  log_error "❌ simple_ios_build.sh not found"
  exit 1
fi

# Check if simple_ios_build.sh is executable
if [ ! -x "lib/scripts/ios-workflow/simple_ios_build.sh" ]; then
  log_warn "⚠️ simple_ios_build.sh is not executable, making it executable..."
  chmod +x lib/scripts/ios-workflow/simple_ios_build.sh
fi

log_success "✅ simple_ios_build.sh found and executable"

# Check Flutter installation
if ! command -v flutter &>/dev/null; then
  log_error "❌ Flutter is not installed"
  exit 1
fi

log_success "✅ Flutter is installed: $(flutter --version | head -1)"

# Check Xcode installation
if ! command -v xcodebuild &>/dev/null; then
  log_error "❌ Xcode is not installed"
  exit 1
fi

log_success "✅ Xcode is installed: $(xcodebuild -version | head -1)"

# Check CocoaPods installation
if ! command -v pod &>/dev/null; then
  log_error "❌ CocoaPods is not installed"
  exit 1
fi

log_success "✅ CocoaPods is installed: $(pod --version)"

# Check if iOS project exists
if [ ! -d "ios" ]; then
  log_warn "⚠️ iOS project not found, will be created during build"
else
  log_success "✅ iOS project directory exists"
fi

# Check if Runner.xcworkspace exists
if [ ! -d "ios/Runner.xcworkspace" ]; then
  log_warn "⚠️ Runner.xcworkspace not found, will be created during build"
else
  log_success "✅ Runner.xcworkspace exists"
fi

# Check if Flutter generated files exist
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
  log_warn "⚠️ ios/Flutter/Generated.xcconfig not found, will be generated during build"
else
  log_success "✅ ios/Flutter/Generated.xcconfig exists"
fi

# Check environment variables
log_info "🔧 Checking environment variables..."

# Required variables
REQUIRED_VARS=("UUID" "BUNDLE_ID" "APPLE_TEAM_ID")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING_VARS+=("$var")
  else
    log_success "✅ $var is set"
  fi
done

# Optional variables with defaults
OPTIONAL_VARS=("CM_DISTRIBUTION_TYPE" "CODE_SIGNING_STYLE" "VERSION_NAME" "VERSION_CODE")
for var in "${OPTIONAL_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    log_warn "⚠️ $var is not set (will use default)"
  else
    log_success "✅ $var is set"
  fi
done

# Certificate variables
CERT_VARS=("CM_PROVISIONING_PROFILE" "CM_CERTIFICATE" "CM_CERTIFICATE_PASSWORD")
CERT_MISSING=0
for var in "${CERT_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    CERT_MISSING=$((CERT_MISSING + 1))
  else
    log_success "✅ $var is set"
  fi
done

if [ $CERT_MISSING -eq ${#CERT_VARS[@]} ]; then
  log_warn "⚠️ No certificate variables set (will use existing keychain)"
elif [ $CERT_MISSING -gt 0 ]; then
  log_warn "⚠️ Some certificate variables are missing"
fi

# App Store Connect variables
ASC_VARS=("APP_STORE_CONNECT_KEY_IDENTIFIER" "APP_STORE_CONNECT_ISSUER_ID")
ASC_MISSING=0
for var in "${ASC_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    ASC_MISSING=$((ASC_MISSING + 1))
  else
    log_success "✅ $var is set"
  fi
done

if [ $ASC_MISSING -eq ${#ASC_VARS[@]} ]; then
  log_warn "⚠️ No App Store Connect variables set (upload will be skipped)"
elif [ $ASC_MISSING -gt 0 ]; then
  log_warn "⚠️ Some App Store Connect variables are missing"
fi

# Check for missing required variables
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  log_warn "⚠️ Missing required environment variables: ${MISSING_VARS[*]}"
  log_info "📋 The script will attempt to extract these from provisioning profiles"
fi

# Check if provisioning profiles directory exists
PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
if [ -d "$PROFILES_HOME" ]; then
  PROFILE_COUNT=$(find "$PROFILES_HOME" -name "*.mobileprovision" | wc -l)
  if [ $PROFILE_COUNT -gt 0 ]; then
    log_success "✅ Found $PROFILE_COUNT provisioning profile(s)"
  else
    log_warn "⚠️ No provisioning profiles found in $PROFILES_HOME"
  fi
else
  log_warn "⚠️ Provisioning profiles directory not found: $PROFILES_HOME"
fi

# Check keychain access
if command -v security &>/dev/null; then
  IDENTITY_COUNT=$(security find-identity -v -p codesigning 2>/dev/null | grep -c "Apple Distribution" || echo "0")
  if [ $IDENTITY_COUNT -gt 0 ]; then
    log_success "✅ Found $IDENTITY_COUNT Apple Distribution signing identity(ies)"
  else
    log_warn "⚠️ No Apple Distribution signing identities found"
  fi
else
  log_warn "⚠️ Cannot check keychain (security command not available)"
fi

# Check if fix scripts exist
FIX_SCRIPTS=("lib/scripts/ios/fix_missing_files.sh" "lib/scripts/ios/fix_preprocessor_directive.sh")
for script in "${FIX_SCRIPTS[@]}"; do
  if [ -f "$script" ]; then
    log_success "✅ $script exists"
  else
    log_warn "⚠️ $script not found (will skip that fix)"
  fi
done

# Check Flutter project
if [ -f "pubspec.yaml" ]; then
  log_success "✅ Flutter project found (pubspec.yaml exists)"
else
  log_error "❌ Not a Flutter project (pubspec.yaml not found)"
  exit 1
fi

# Check main.dart
if [ -f "lib/main.dart" ]; then
  log_success "✅ lib/main.dart exists"
else
  log_error "❌ lib/main.dart not found"
  exit 1
fi

# Check for critical Dart files
CRITICAL_FILES=("lib/config/env_config.dart" "lib/module/myapp.dart")
for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    log_success "✅ $file exists"
  else
    log_warn "⚠️ $file not found (will be restored if backup exists)"
  fi
done

# Test Flutter doctor
log_info "🔍 Running Flutter doctor..."
if flutter doctor > /dev/null 2>&1; then
  log_success "✅ Flutter doctor passed"
else
  log_warn "⚠️ Flutter doctor had issues (continuing anyway)"
fi

# Summary
echo ""
echo "📊 Test Summary:"
echo "=================="

if [ ${#MISSING_VARS[@]} -eq 0 ]; then
  log_success "✅ All required environment variables are set"
else
  log_warn "⚠️ Missing variables: ${MISSING_VARS[*]} (will be extracted from profiles)"
fi

if [ $CERT_MISSING -eq 0 ]; then
  log_success "✅ All certificate variables are set"
else
  log_warn "⚠️ Some certificate variables missing (will use existing keychain)"
fi

if [ $ASC_MISSING -eq 0 ]; then
  log_success "✅ All App Store Connect variables are set"
else
  log_warn "⚠️ App Store Connect variables missing (upload will be skipped)"
fi

log_success "🎉 Simple iOS Workflow test completed!"
log_info "📋 Ready to run: ./lib/scripts/ios-workflow/simple_ios_build.sh" 