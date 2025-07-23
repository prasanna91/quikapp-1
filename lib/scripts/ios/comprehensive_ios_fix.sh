#!/bin/bash

# Comprehensive iOS Build Fix Script
# Fixes all common iOS build issues including Firebase conflicts and CocoaPods problems

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Running Comprehensive iOS Build Fix..."

# Step 1: Update Firebase versions
log_info "📦 Step 1: Updating Firebase versions..."
if [ -f "lib/scripts/ios/update_firebase_versions.sh" ]; then
  chmod +x lib/scripts/ios/update_firebase_versions.sh
  if ./lib/scripts/ios/update_firebase_versions.sh; then
    log_success "✅ Firebase versions updated"
  else
    log_warn "⚠️ Firebase version update failed, continuing..."
  fi
else
  log_warn "⚠️ Firebase version update script not found"
fi

# Step 2: Fix Podfile deployment target
log_info "📱 Step 2: Fixing Podfile deployment target..."
if [ -f "lib/scripts/ios/fix_podfile_deployment_target.sh" ]; then
  chmod +x lib/scripts/ios/fix_podfile_deployment_target.sh
  if ./lib/scripts/ios/fix_podfile_deployment_target.sh; then
    log_success "✅ Podfile deployment target fixed"
  else
    log_warn "⚠️ Podfile deployment target fix failed, continuing..."
  fi
else
  log_warn "⚠️ Podfile deployment target fix script not found"
fi

# Step 3: Fix Firebase version conflicts
log_info "🔥 Step 3: Fixing Firebase version conflicts..."
if [ -f "lib/scripts/ios/fix_firebase_version_conflict.sh" ]; then
  chmod +x lib/scripts/ios/fix_firebase_version_conflict.sh
  if ./lib/scripts/ios/fix_firebase_version_conflict.sh; then
    log_success "✅ Firebase version conflicts resolved"
  else
    log_warn "⚠️ Firebase version conflict resolution failed, continuing..."
  fi
else
  log_warn "⚠️ Firebase version conflict fix script not found"
fi

# Step 4: Run CocoaPods integration fix
log_info "📦 Step 4: Running CocoaPods integration fix..."
if [ -f "lib/scripts/ios/cocoapods_integration_fix.sh" ]; then
  chmod +x lib/scripts/ios/cocoapods_integration_fix.sh
  if ./lib/scripts/ios/cocoapods_integration_fix.sh; then
    log_success "✅ CocoaPods integration fix completed"
  else
    log_warn "⚠️ CocoaPods integration fix failed, continuing..."
  fi
else
  log_warn "⚠️ CocoaPods integration fix script not found"
fi

# Step 5: Manual CocoaPods cleanup and reinstall
log_info "🧹 Step 5: Manual CocoaPods cleanup and reinstall..."
cd ios

# Remove existing Pods and lock file
if [ -f "Podfile.lock" ]; then
  log_info "🗑️ Removing Podfile.lock..."
  rm -f Podfile.lock
fi

if [ -d "Pods" ]; then
  log_info "🗑️ Removing Pods directory..."
  rm -rf Pods
fi

# Clear CocoaPods cache
log_info "🧹 Clearing CocoaPods cache..."
pod cache clean --all || true

# Update repository and install
log_info "🔄 Updating CocoaPods repository..."
pod repo update --silent || log_warn "⚠️ Repository update failed, continuing..."

log_info "📦 Installing pods with fresh repository..."
if pod install --repo-update --clean-install; then
  log_success "✅ CocoaPods installation successful"
else
  log_error "❌ CocoaPods installation failed"
  cd ..
  exit 1
fi

cd ..

# Step 6: Verify installation
log_info "🔍 Step 6: Verifying installation..."
if [ -d "ios/Pods" ] && [ -f "ios/Podfile.lock" ]; then
  log_success "✅ Pods directory and Podfile.lock exist"
  
  # Check for Firebase pods
  if [ -d "ios/Pods/Firebase" ]; then
    log_success "✅ Firebase pods found"
  else
    log_warn "⚠️ Firebase pods not found (this might be normal if Firebase is not configured)"
  fi
else
  log_error "❌ Pods installation verification failed"
  exit 1
fi

log_success "🎉 Comprehensive iOS build fix completed successfully!"
log_info "📋 You can now run the iOS build process" 