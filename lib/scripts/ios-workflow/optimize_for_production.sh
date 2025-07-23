#!/bin/bash

# iOS Workflow Production Optimization Script
# Optimizes the workflow for reliable production builds

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🚀 Optimizing iOS Workflow for Production Builds..."

# Function to optimize Podfile
optimize_podfile() {
  log_info "📱 Optimizing Podfile..."
  
  if [ -f "ios/Podfile" ]; then
    # Ensure platform is set to iOS 13.0
    if ! grep -q "platform :ios, '13.0'" "ios/Podfile"; then
      log_info "🔄 Updating iOS deployment target to 13.0..."
      sed -i '' "s/platform :ios, '[0-9.]*'/platform :ios, '13.0'/g" "ios/Podfile"
      sed -i '' "s/# platform :ios, '[0-9.]*'/platform :ios, '13.0'/g" "ios/Podfile"
    fi
    
    # Ensure use_frameworks! is present
    if ! grep -q "use_frameworks!" "ios/Podfile"; then
      log_info "🔄 Adding use_frameworks! to Podfile..."
      sed -i '' "/platform :ios/a\\
use_frameworks!
" "ios/Podfile"
    fi
    
    log_success "✅ Podfile optimized"
  else
    log_error "❌ Podfile not found"
    return 1
  fi
}

# Function to optimize release.xcconfig
optimize_release_config() {
  log_info "🔧 Optimizing release.xcconfig..."
  
  if [ -f "ios/Flutter/release.xcconfig" ]; then
    # Add optimization flags
    {
      echo "# Production optimizations"
      echo "ENABLE_BITCODE = NO"
      echo "STRIP_INSTALLED_PRODUCT = YES"
      echo "COPY_PHASE_STRIP = YES"
      echo "DEAD_CODE_STRIPPING = YES"
      echo "ONLY_ACTIVE_ARCH = NO"
    } >> "ios/Flutter/release.xcconfig"
    
    log_success "✅ release.xcconfig optimized"
  else
    log_warn "⚠️ release.xcconfig not found"
  fi
}

# Function to optimize Info.plist
optimize_info_plist() {
  log_info "📱 Optimizing Info.plist..."
  
  if [ -f "ios/Runner/Info.plist" ]; then
    # Add production optimizations
    /usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "ios/Runner/Info.plist" 2>/dev/null || true
    
    log_success "✅ Info.plist optimized"
  else
    log_warn "⚠️ Info.plist not found"
  fi
}

# Function to clean build artifacts
clean_build_artifacts() {
  log_info "🧹 Cleaning build artifacts..."
  
  # Clean Flutter
  flutter clean 2>/dev/null || true
  
  # Clean iOS build
  rm -rf ios/build/ 2>/dev/null || true
  rm -rf ios/Pods/ 2>/dev/null || true
  rm -f ios/Podfile.lock 2>/dev/null || true
  
  # Clean output directories
  rm -rf build/ios/ 2>/dev/null || true
  rm -rf output/ 2>/dev/null || true
  
  log_success "✅ Build artifacts cleaned"
}

# Function to update Flutter dependencies
update_flutter_dependencies() {
  log_info "📦 Updating Flutter dependencies..."
  
  if flutter pub get; then
    log_success "✅ Flutter dependencies updated"
  else
    log_error "❌ Failed to update Flutter dependencies"
    return 1
  fi
}

# Function to prepare CocoaPods
prepare_cocoapods() {
  log_info "📦 Preparing CocoaPods..."
  
  cd ios
  
  # Update repository
  if command -v pod &>/dev/null; then
    pod repo update --silent || log_warn "⚠️ Repository update failed"
    
    # Install pods
    if pod install --repo-update --clean-install; then
      log_success "✅ CocoaPods prepared"
    else
      log_error "❌ CocoaPods installation failed"
      cd ..
      return 1
    fi
  else
    log_warn "⚠️ CocoaPods not available (expected in CI)"
  fi
  
  cd ..
}

# Function to validate build readiness
validate_build_readiness() {
  log_info "🔍 Validating build readiness..."
  
  # Check critical files
  CRITICAL_FILES=(
    "ios/Podfile"
    "ios/Runner.xcworkspace"
    "ios/Runner/Info.plist"
    "ios/Flutter/release.xcconfig"
    "pubspec.yaml"
    "lib/main.dart"
  )
  
  for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
      log_success "✅ $file exists"
    else
      log_error "❌ $file missing"
      return 1
    fi
  done
  
  # Check if Pods directory exists (if CocoaPods is available)
  if command -v pod &>/dev/null && [ ! -d "ios/Pods" ]; then
    log_warn "⚠️ Pods directory not found, running pod install..."
    prepare_cocoapods
  fi
  
  log_success "✅ Build readiness validated"
  return 0
}

# Function to create production build script
create_production_build_script() {
  log_info "📝 Creating production build script..."
  
  cat > "lib/scripts/ios/production_build.sh" << 'EOF'
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
EOF

  chmod +x "lib/scripts/ios/production_build.sh"
  log_success "✅ Production build script created"
}

# Main execution
echo "🔧 Running production optimizations..."

# Run all optimizations
optimize_podfile
optimize_release_config
optimize_info_plist
clean_build_artifacts
update_flutter_dependencies
prepare_cocoapods
validate_build_readiness
create_production_build_script

echo ""
log_info "💡 Production Optimization Complete!"
echo ""
echo "🚀 Ready for production builds with:"
echo "   - Optimized Podfile with iOS 13.0 deployment target"
echo "   - Enhanced release.xcconfig with production flags"
echo "   - Cleaned build artifacts"
echo "   - Updated dependencies"
echo "   - Validated build readiness"
echo ""
echo "📋 Use the production build script:"
echo "   ./lib/scripts/ios/production_build.sh"
echo ""

log_success "🎉 iOS Workflow optimized for production!" 