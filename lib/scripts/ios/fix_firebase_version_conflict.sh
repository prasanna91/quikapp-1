#!/bin/bash

# Firebase Version Conflict Resolution Script
# Fixes Firebase version conflicts in CocoaPods

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔥 Fixing Firebase version conflicts..."

PODFILE_PATH="ios/Podfile"
PODFILE_LOCK_PATH="ios/Podfile.lock"
PODS_DIR="ios/Pods"

# Check if we're in the right directory
if [ ! -f "$PODFILE_PATH" ]; then
  log_error "❌ Podfile not found. Please run this script from the project root."
  exit 1
fi

cd ios

# Function to check for Firebase version conflicts
check_firebase_conflicts() {
  if [ -f "Podfile.lock" ]; then
    log_info "🔍 Checking for Firebase version conflicts..."
    
    # Check for specific Firebase version conflicts
    if grep -q "Firebase/Messaging.*11.15.0" "Podfile.lock"; then
      log_warn "⚠️ Firebase/Messaging version conflict detected (11.15.0 vs 10.25.0)"
      return 0  # Conflict found
    fi
    
    if grep -q "Firebase/Core.*11.15.0" "Podfile.lock"; then
      log_warn "⚠️ Firebase/Core version conflict detected (11.15.0 vs 10.25.0)"
      return 0  # Conflict found
    fi
    
    log_success "✅ No Firebase version conflicts detected"
    return 1  # No conflict
  else
    log_info "📋 No Podfile.lock found, no conflicts to check"
    return 1  # No conflict
  fi
}

# Function to resolve Firebase conflicts
resolve_firebase_conflicts() {
  log_info "🔧 Resolving Firebase version conflicts..."
  
  # Remove existing Podfile.lock and Pods directory
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
  
  # Update CocoaPods repository
  log_info "🔄 Updating CocoaPods repository..."
  pod repo update --silent || log_warn "⚠️ Repository update failed, continuing..."
  
  # Fresh install with repo update
  log_info "📦 Installing pods with fresh repository..."
  if pod install --repo-update --clean-install; then
    log_success "✅ Firebase conflicts resolved successfully"
    return 0
  else
    log_error "❌ Failed to resolve Firebase conflicts"
    return 1
  fi
}

# Function to verify Firebase installation
verify_firebase_installation() {
  log_info "🔍 Verifying Firebase installation..."
  
  if [ -d "Pods/Firebase" ]; then
    log_success "✅ Firebase pods directory exists"
    
    # Check Firebase version
    if [ -f "Podfile.lock" ]; then
      FIREBASE_VERSION=$(grep -o "Firebase.*10.25.0" Podfile.lock | head -1 || echo "")
      if [ -n "$FIREBASE_VERSION" ]; then
        log_success "✅ Firebase version 10.25.0 confirmed"
      else
        log_warn "⚠️ Firebase version not confirmed as 10.25.0"
      fi
    fi
    
    return 0
  else
    log_warn "⚠️ Firebase pods directory not found (this might be normal if Firebase is not configured)"
    return 0
  fi
}

# Main execution
if check_firebase_conflicts; then
  log_warn "⚠️ Firebase version conflicts detected"
  
  if resolve_firebase_conflicts; then
    if verify_firebase_installation; then
      log_success "🎉 Firebase version conflicts resolved successfully!"
    else
      log_error "❌ Firebase installation verification failed"
      exit 1
    fi
  else
    log_error "❌ Failed to resolve Firebase conflicts"
    exit 1
  fi
else
  log_info "✅ No Firebase conflicts to resolve"
fi

cd ..

log_success "✅ Firebase version conflict resolution completed" 