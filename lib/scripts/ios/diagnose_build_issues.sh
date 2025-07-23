#!/bin/bash

# iOS Build Diagnostic Script
# Helps identify common build issues and provides solutions

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔍 Running iOS Build Diagnostics..."

# Function to check Flutter environment
check_flutter_environment() {
  log_info "📱 Checking Flutter environment..."
  
  if ! command -v flutter &>/dev/null; then
    log_error "❌ Flutter is not installed"
    return 1
  fi
  
  log_info "Flutter version: $(flutter --version | head -1)"
  log_info "Flutter doctor:"
  flutter doctor --verbose
  
  return 0
}

# Function to check iOS project structure
check_ios_project() {
  log_info "📱 Checking iOS project structure..."
  
  if [ ! -d "ios" ]; then
    log_error "❌ iOS directory not found"
    return 1
  fi
  
  if [ ! -f "ios/Podfile" ]; then
    log_error "❌ Podfile not found"
    return 1
  fi
  
  if [ ! -d "ios/Runner.xcworkspace" ]; then
    log_error "❌ Runner.xcworkspace not found"
    return 1
  fi
  
  if [ ! -f "ios/Runner/Info.plist" ]; then
    log_error "❌ Info.plist not found"
    return 1
  fi
  
  log_success "✅ iOS project structure is correct"
  return 0
}

# Function to check CocoaPods setup
check_cocoapods_setup() {
  log_info "📦 Checking CocoaPods setup..."
  
  if ! command -v pod &>/dev/null; then
    log_error "❌ CocoaPods is not installed"
    return 1
  fi
  
  log_info "CocoaPods version: $(pod --version)"
  
  cd ios
  
  if [ -f "Podfile.lock" ]; then
    log_info "Podfile.lock exists"
    log_info "Podfile.lock contents:"
    head -20 Podfile.lock
  else
    log_warn "⚠️ Podfile.lock not found"
  fi
  
  if [ -d "Pods" ]; then
    log_info "Pods directory exists"
    log_info "Pods directory contents:"
    ls -la Pods/ | head -10
  else
    log_warn "⚠️ Pods directory not found"
  fi
  
  cd ..
  return 0
}

# Function to check environment variables
check_environment_variables() {
  log_info "🔍 Checking environment variables..."
  
  REQUIRED_VARS=("APPLE_TEAM_ID" "CM_PROVISIONING_PROFILE" "CM_CERTIFICATE" "CM_CERTIFICATE_PASSWORD")
  MISSING_VARS=()
  
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_VARS+=("$var")
    else
      log_info "✅ $var is set"
    fi
  done
  
  if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_warn "⚠️ Missing environment variables: ${MISSING_VARS[*]}"
    return 1
  else
    log_success "✅ All required environment variables are set"
    return 0
  fi
}

# Function to check Xcode setup
check_xcode_setup() {
  log_info "🔧 Checking Xcode setup..."
  
  if ! command -v xcodebuild &>/dev/null; then
    log_error "❌ Xcode command line tools not installed"
    return 1
  fi
  
  log_info "Xcode version: $(xcodebuild -version | head -1)"
  
  # Check available SDKs
  log_info "Available iOS SDKs:"
  xcodebuild -showsdks | grep iOS || log_warn "⚠️ No iOS SDKs found"
  
  return 0
}

# Function to check code signing setup
check_code_signing() {
  log_info "🔐 Checking code signing setup..."
  
  # Check if keychain is accessible
  if security list-keychains 2>/dev/null | grep -q "login.keychain"; then
    log_success "✅ Keychain is accessible"
  else
    log_warn "⚠️ Keychain accessibility issues"
  fi
  
  # Check for signing identities
  log_info "Available signing identities:"
  security find-identity -v -p codesigning || log_warn "⚠️ No signing identities found"
  
  return 0
}

# Function to check for common build issues
check_common_issues() {
  log_info "🔍 Checking for common build issues..."
  
  # Check for Firebase configuration
  if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    log_success "✅ Firebase configuration file found"
  else
    log_warn "⚠️ Firebase configuration file not found"
  fi
  
  # Check for bundle identifier conflicts
  if grep -q "com.example" ios/Runner/Info.plist; then
    log_warn "⚠️ Default bundle identifier found in Info.plist"
  fi
  
  # Check for deployment target issues
  if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*12.0" ios/Podfile; then
    log_warn "⚠️ iOS deployment target is 12.0 (should be 13.0 for Firebase)"
  fi
  
  return 0
}

# Function to provide recommendations
provide_recommendations() {
  log_info "💡 Build recommendations:"
  
  echo "1. Ensure all environment variables are set:"
  echo "   - APPLE_TEAM_ID"
  echo "   - CM_PROVISIONING_PROFILE"
  echo "   - CM_CERTIFICATE"
  echo "   - CM_CERTIFICATE_PASSWORD"
  echo ""
  echo "2. Run the comprehensive fix script:"
  echo "   ./lib/scripts/ios/comprehensive_ios_fix.sh"
  echo ""
  echo "3. If build still fails, check the detailed logs:"
  echo "   - flutter_build_*.log"
  echo "   - xcodebuild_archive_*.log"
  echo "   - xcodebuild_export_*.log"
  echo ""
  echo "4. Common solutions:"
  echo "   - Clean and rebuild: flutter clean && flutter pub get"
  echo "   - Update CocoaPods: pod repo update && pod install"
  echo "   - Check code signing: security find-identity -v -p codesigning"
}

# Main execution
echo "🔧 Running comprehensive diagnostics..."

check_flutter_environment
check_ios_project
check_cocoapods_setup
check_environment_variables
check_xcode_setup
check_code_signing
check_common_issues

echo ""
provide_recommendations

log_success "✅ Diagnostics completed" 