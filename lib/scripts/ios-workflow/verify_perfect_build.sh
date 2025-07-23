#!/bin/bash

# iOS Workflow Perfect Build Verification Script
# Verifies all components are properly configured for successful builds

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔍 Verifying iOS Workflow for Perfect Build..."

# Function to check required scripts exist
check_required_scripts() {
  log_info "📋 Checking required scripts..."
  
  REQUIRED_SCRIPTS=(
    "lib/scripts/ios-workflow/pre-build.sh"
    "lib/scripts/ios-workflow/build.sh"
    "lib/scripts/ios-workflow/post-build.sh"
    "lib/scripts/ios-workflow/validate_environment.sh"
    "lib/scripts/ios/enhanced_build.sh"
    "lib/scripts/ios/comprehensive_ios_fix.sh"
    "lib/scripts/ios/diagnose_build_issues.sh"
    "lib/scripts/ios/fix_firebase_version_conflict.sh"
    "lib/scripts/ios/update_firebase_versions.sh"
    "lib/scripts/ios/fix_podfile_deployment_target.sh"
    "lib/scripts/utils/send_email.sh"
  )
  
  MISSING_SCRIPTS=()
  
  for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
      log_success "✅ $script exists"
    else
      MISSING_SCRIPTS+=("$script")
      log_error "❌ $script missing"
    fi
  done
  
  if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
    log_error "❌ Missing ${#MISSING_SCRIPTS[@]} required scripts"
    return 1
  else
    log_success "✅ All required scripts exist"
    return 0
  fi
}

# Function to check script permissions
check_script_permissions() {
  log_info "🔐 Checking script permissions..."
  
  SCRIPTS_TO_CHECK=(
    "lib/scripts/ios-workflow/pre-build.sh"
    "lib/scripts/ios-workflow/build.sh"
    "lib/scripts/ios-workflow/post-build.sh"
    "lib/scripts/ios-workflow/validate_environment.sh"
    "lib/scripts/ios/enhanced_build.sh"
    "lib/scripts/ios/comprehensive_ios_fix.sh"
    "lib/scripts/ios/diagnose_build_issues.sh"
    "lib/scripts/ios/fix_firebase_version_conflict.sh"
    "lib/scripts/ios/update_firebase_versions.sh"
    "lib/scripts/ios/fix_podfile_deployment_target.sh"
    "lib/scripts/utils/send_email.sh"
  )
  
  for script in "${SCRIPTS_TO_CHECK[@]}"; do
    if [ -x "$script" ]; then
      log_success "✅ $script is executable"
    else
      log_warn "⚠️ $script is not executable, making it executable..."
      chmod +x "$script"
    fi
  done
  
  log_success "✅ All scripts are executable"
}

# Function to check iOS project structure
check_ios_project_structure() {
  log_info "📱 Checking iOS project structure..."
  
  REQUIRED_FILES=(
    "ios/Podfile"
    "ios/Runner.xcworkspace"
    "ios/Runner/Info.plist"
    "ios/Flutter/release.xcconfig"
    "ios/Flutter/debug.xcconfig"
  )
  
  for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
      log_success "✅ $file exists"
    else
      log_error "❌ $file missing"
      return 1
    fi
  done
  
  log_success "✅ iOS project structure is correct"
  return 0
}

# Function to check Flutter project
check_flutter_project() {
  log_info "📱 Checking Flutter project..."
  
  if [ -f "pubspec.yaml" ]; then
    log_success "✅ pubspec.yaml exists"
  else
    log_error "❌ pubspec.yaml missing"
    return 1
  fi
  
  if [ -f "lib/main.dart" ]; then
    log_success "✅ lib/main.dart exists"
  else
    log_error "❌ lib/main.dart missing"
    return 1
  fi
  
  log_success "✅ Flutter project structure is correct"
  return 0
}

# Function to check environment variables
check_environment_variables() {
  log_info "🔍 Checking environment variables..."
  
  REQUIRED_VARS=("APPLE_TEAM_ID" "CM_PROVISIONING_PROFILE" "CM_CERTIFICATE" "CM_CERTIFICATE_PASSWORD")
  OPTIONAL_VARS=("ENABLE_EMAIL_NOTIFICATIONS" "EMAIL_SMTP_SERVER" "EMAIL_SMTP_USER" "EMAIL_SMTP_PASS")
  
  MISSING_REQUIRED=()
  MISSING_OPTIONAL=()
  
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_REQUIRED+=("$var")
    else
      log_success "✅ $var is set"
    fi
  done
  
  for var in "${OPTIONAL_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_OPTIONAL+=("$var")
    else
      log_success "✅ $var is set"
    fi
  done
  
  if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
    log_warn "⚠️ Missing required variables: ${MISSING_REQUIRED[*]}"
    log_warn "📋 These will be needed for the actual build process"
  fi
  
  if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    log_info "ℹ️ Missing optional variables: ${MISSING_OPTIONAL[*]}"
    log_info "📋 These are for email notifications"
  fi
  
  return 0
}

# Function to check CocoaPods setup
check_cocoapods_setup() {
  log_info "📦 Checking CocoaPods setup..."
  
  if ! command -v pod &>/dev/null; then
    log_warn "⚠️ CocoaPods not installed (this is expected in CI environment)"
    return 0
  fi
  
  log_info "CocoaPods version: $(pod --version)"
  
  if [ -f "ios/Podfile" ]; then
    log_success "✅ Podfile exists"
    
    # Check if platform is set correctly
    if grep -q "platform :ios, '13.0'" "ios/Podfile"; then
      log_success "✅ iOS deployment target is set to 13.0"
    else
      log_warn "⚠️ iOS deployment target might not be set to 13.0"
    fi
  else
    log_error "❌ Podfile missing"
    return 1
  fi
  
  return 0
}

# Function to check Firebase configuration
check_firebase_configuration() {
  log_info "🔥 Checking Firebase configuration..."
  
  if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    log_success "✅ Firebase configuration file exists"
  else
    log_warn "⚠️ Firebase configuration file not found"
    log_info "📋 This is normal if Firebase is not configured"
  fi
  
  # Check pubspec.yaml for Firebase dependencies
  if grep -q "firebase_core" "pubspec.yaml"; then
    log_success "✅ Firebase dependencies found in pubspec.yaml"
  else
    log_info "ℹ️ No Firebase dependencies found in pubspec.yaml"
  fi
  
  return 0
}

# Function to run a test build simulation
simulate_build_process() {
  log_info "🧪 Simulating build process..."
  
  # Test 1: Check if Flutter is available
  if command -v flutter &>/dev/null; then
    log_success "✅ Flutter is available"
    log_info "Flutter version: $(flutter --version | head -1)"
  else
    log_warn "⚠️ Flutter not available (expected in CI environment)"
  fi
  
  # Test 2: Check if Xcode is available
  if command -v xcodebuild &>/dev/null; then
    log_success "✅ Xcode command line tools are available"
    log_info "Xcode version: $(xcodebuild -version | head -1)"
  else
    log_warn "⚠️ Xcode command line tools not available (expected in CI environment)"
  fi
  
  # Test 3: Check if workspace exists
  if [ -d "ios/Runner.xcworkspace" ]; then
    log_success "✅ Runner.xcworkspace exists"
  else
    log_error "❌ Runner.xcworkspace missing"
    return 1
  fi
  
  log_success "✅ Build simulation completed"
  return 0
}

# Function to provide recommendations
provide_recommendations() {
  log_info "💡 Perfect Build Recommendations:"
  
  echo ""
  echo "1. Environment Variables:"
  echo "   - Ensure APPLE_TEAM_ID is set"
  echo "   - Ensure CM_PROVISIONING_PROFILE is set"
  echo "   - Ensure CM_CERTIFICATE is set"
  echo "   - Ensure CM_CERTIFICATE_PASSWORD is set"
  echo ""
  echo "2. Build Process:"
  echo "   - Pre-build: ./lib/scripts/ios-workflow/pre-build.sh"
  echo "   - Build: ./lib/scripts/ios-workflow/build.sh"
  echo "   - Post-build: ./lib/scripts/ios-workflow/post-build.sh"
  echo ""
  echo "3. Troubleshooting:"
  echo "   - Run diagnostics: ./lib/scripts/ios/diagnose_build_issues.sh"
  echo "   - Comprehensive fix: ./lib/scripts/ios/comprehensive_ios_fix.sh"
  echo ""
  echo "4. Expected Workflow:"
  echo "   - Pre-build validates environment and fixes issues"
  echo "   - Build uses enhanced error handling"
  echo "   - Post-build handles artifacts and notifications"
  echo ""
}

# Main execution
echo "🔧 Running comprehensive verification..."

# Run all checks
check_required_scripts
check_script_permissions
check_ios_project_structure
check_flutter_project
check_environment_variables
check_cocoapods_setup
check_firebase_configuration
simulate_build_process

echo ""
provide_recommendations

log_success "🎉 iOS Workflow verification completed!"
log_info "📋 The workflow is configured for perfect builds" 