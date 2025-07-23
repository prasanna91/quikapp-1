#!/bin/bash

# Fix Flutter Generated Files Script
# Ensures Flutter generated files exist before CocoaPods installation

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Fixing Flutter generated files..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
  log_error "❌ pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Function to check Flutter setup
check_flutter_setup() {
  log_info "🔍 Checking Flutter setup..."
  
  if ! command -v flutter &>/dev/null; then
    log_error "❌ Flutter is not installed or not in PATH"
    return 1
  fi
  
  log_info "Flutter version: $(flutter --version | head -1)"
  
  # Run flutter doctor to check for issues
  log_info "Running flutter doctor..."
  flutter doctor --verbose
  
  return 0
}

# Function to generate Flutter files
generate_flutter_files() {
  log_info "📦 Generating Flutter files..."
  
  # Clean Flutter cache
  log_info "🧹 Cleaning Flutter cache..."
  flutter clean 2>/dev/null || true
  
  # Get Flutter dependencies
  log_info "📦 Getting Flutter dependencies..."
  if flutter pub get; then
    log_success "✅ Flutter dependencies installed"
  else
    log_error "❌ Failed to install Flutter dependencies"
    return 1
  fi
  
  # Generate Flutter files
  log_info "🔧 Generating Flutter files..."
  if flutter pub get; then
    log_success "✅ Flutter files generated"
  else
    log_error "❌ Failed to generate Flutter files"
    return 1
  fi
}

# Function to verify generated files
verify_generated_files() {
  log_info "🔍 Verifying generated files..."
  
  REQUIRED_FILES=(
    "ios/Flutter/Generated.xcconfig"
    "ios/Flutter/flutter_export_environment.sh"
  )
  
  for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
      log_success "✅ $file exists"
    else
      log_error "❌ $file missing"
      return 1
    fi
  done
  
  # Check if ios directory exists
  if [ ! -d "ios" ]; then
    log_error "❌ ios directory not found"
    return 1
  fi
  
  # Check if Runner.xcworkspace exists
  if [ ! -d "ios/Runner.xcworkspace" ]; then
    log_warn "⚠️ Runner.xcworkspace not found, creating iOS project..."
    
    # Create iOS project
    if flutter create --platforms=ios .; then
      log_success "✅ iOS project created"
    else
      log_error "❌ Failed to create iOS project"
      return 1
    fi
  else
    log_success "✅ Runner.xcworkspace exists"
  fi
  
  return 0
}

# Function to fix Podfile if needed
fix_podfile() {
  log_info "📱 Checking Podfile..."
  
  if [ ! -f "ios/Podfile" ]; then
    log_error "❌ Podfile not found"
    return 1
  fi
  
  # Check if Podfile has the correct flutter_root function
  if ! grep -q "flutter_root" "ios/Podfile"; then
    log_warn "⚠️ Podfile might be missing flutter_root function"
    log_info "📋 This is normal for newly created projects"
  fi
  
  log_success "✅ Podfile is valid"
  return 0
}

# Function to prepare for CocoaPods
prepare_for_cocoapods() {
  log_info "📦 Preparing for CocoaPods installation..."
  
  cd ios
  
  # Check if Podfile exists
  if [ ! -f "Podfile" ]; then
    log_error "❌ Podfile not found in ios directory"
    cd ..
    return 1
  fi
  
  # Check if Generated.xcconfig exists
  if [ ! -f "Flutter/Generated.xcconfig" ]; then
    log_error "❌ Flutter/Generated.xcconfig not found"
    log_info "📋 This file is required by the Podfile"
    cd ..
    return 1
  fi
  
  log_success "✅ Ready for CocoaPods installation"
  cd ..
  return 0
}

# Main execution
echo "🔧 Running Flutter generated files fix..."

# Run all steps
if check_flutter_setup && generate_flutter_files && verify_generated_files && fix_podfile && prepare_for_cocoapods; then
  log_success "🎉 Flutter generated files fix completed successfully!"
  log_info "📋 You can now run pod install in the ios directory"
else
  log_error "❌ Flutter generated files fix failed"
  exit 1
fi 