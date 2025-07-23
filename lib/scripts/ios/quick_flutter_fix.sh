#!/bin/bash

# Quick Flutter Fix Script
# Immediately resolves the Flutter generated files issue

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }

echo "🚀 Quick Flutter Fix - Resolving Generated Files Issue..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
  log_error "❌ pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Step 1: Clean Flutter
log_info "🧹 Step 1: Cleaning Flutter..."
flutter clean 2>/dev/null || true

# Step 2: Get Flutter dependencies
log_info "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

# Step 3: Create iOS project if it doesn't exist
log_info "📱 Step 3: Ensuring iOS project exists..."
if [ ! -d "ios" ]; then
  log_info "Creating iOS project..."
  flutter create --platforms=ios .
fi

# Step 4: Verify generated files
log_info "🔍 Step 4: Verifying generated files..."
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
  log_success "✅ ios/Flutter/Generated.xcconfig exists"
else
  log_error "❌ ios/Flutter/Generated.xcconfig still missing"
  log_info "📋 Running flutter pub get again..."
  flutter pub get
fi

# Step 5: Check Runner.xcworkspace
log_info "📱 Step 5: Checking Runner.xcworkspace..."
if [ -d "ios/Runner.xcworkspace" ]; then
  log_success "✅ ios/Runner.xcworkspace exists"
else
  log_error "❌ ios/Runner.xcworkspace missing"
  log_info "📋 Creating iOS project..."
  flutter create --platforms=ios .
fi

# Step 6: Final verification
log_info "🔍 Step 6: Final verification..."
if [ -f "ios/Flutter/Generated.xcconfig" ] && [ -d "ios/Runner.xcworkspace" ]; then
  log_success "🎉 Quick Flutter fix completed successfully!"
  log_info "📋 You can now run pod install in the ios directory"
else
  log_error "❌ Quick Flutter fix failed"
  log_info "📋 Generated files still missing"
  exit 1
fi 