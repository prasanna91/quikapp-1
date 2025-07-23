#!/bin/bash

# Podfile Check and Fix Script
# Checks for common issues in Podfile and fixes them

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔍 Checking Podfile for common issues..."

PODFILE_PATH="ios/Podfile"

if [ ! -f "$PODFILE_PATH" ]; then
    log_error "Podfile not found at $PODFILE_PATH"
    exit 1
fi

log_info "✅ Podfile found"

# Check if Podfile has proper structure
if ! grep -q "platform :ios" "$PODFILE_PATH"; then
    log_error "❌ Podfile missing platform :ios declaration"
    exit 1
fi

if ! grep -q "target 'Runner'" "$PODFILE_PATH"; then
    log_error "❌ Podfile missing target 'Runner' declaration"
    exit 1
fi

log_success "✅ Podfile structure looks correct"

# Check for common issues and fix them
log_info "🔧 Checking for common Podfile issues..."

# Check if use_frameworks! is present (required for Flutter)
if ! grep -q "use_frameworks!" "$PODFILE_PATH"; then
    log_warn "⚠️ use_frameworks! not found, this might cause issues"
fi

# Check if post_install hook is present and has correct deployment target
if ! grep -q "post_install" "$PODFILE_PATH"; then
    log_warn "⚠️ post_install hook not found, this might cause build issues"
else
    # Check if post_install has correct deployment target
    if ! grep -q "IPHONEOS_DEPLOYMENT_TARGET = '13.0'" "$PODFILE_PATH"; then
        log_warn "⚠️ post_install hook deployment target might be too old for Firebase"
    else
        log_success "✅ post_install hook has correct deployment target"
    fi
fi

# Check for minimum iOS version (Firebase requires iOS 13.0+)
if ! grep -q "platform :ios, '13.0'" "$PODFILE_PATH" && ! grep -q "platform :ios, '14.0'" "$PODFILE_PATH" && ! grep -q "platform :ios, '15.0'" "$PODFILE_PATH"; then
    log_error "❌ iOS platform version too old for Firebase (requires iOS 13.0+)"
    log_error "Current platform: $(grep -o "platform :ios, '[0-9.]*'" "$PODFILE_PATH" | head -1 || echo 'Not specified')"
    return 1
fi

# Check if Podfile.lock exists and is readable
if [ -f "ios/Podfile.lock" ]; then
    log_info "✅ Podfile.lock exists"
    if [ ! -r "ios/Podfile.lock" ]; then
        log_error "❌ Podfile.lock is not readable"
        chmod 644 ios/Podfile.lock
        log_success "✅ Fixed Podfile.lock permissions"
    fi
else
    log_info "ℹ️ Podfile.lock does not exist (this is normal for first run)"
fi

# Check CocoaPods version
if command -v pod &>/dev/null; then
    POD_VERSION=$(pod --version)
    log_info "📦 CocoaPods version: $POD_VERSION"
    
    # Check if version is compatible
    if [[ "$POD_VERSION" < "1.10.0" ]]; then
        log_warn "⚠️ CocoaPods version might be too old: $POD_VERSION"
    fi
else
    log_error "❌ CocoaPods not installed"
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "ios" ]; then
    log_error "❌ Not in project root directory"
    exit 1
fi

log_success "✅ Podfile check completed"

# Try to run pod install with verbose output for debugging
log_info "🔄 Testing pod install..."
cd ios

# Create a temporary Podfile.lock backup if it exists
if [ -f "Podfile.lock" ]; then
    cp Podfile.lock Podfile.lock.backup
    log_info "🗂️ Backed up Podfile.lock"
fi

# Run pod install with verbose output
if pod install --verbose 2>&1 | tee /tmp/pod_install_verbose.log; then
    log_success "✅ pod install test successful"
    cd ..
    return 0
else
    log_error "❌ pod install test failed"
    log_error "Verbose pod install error log:"
    cat /tmp/pod_install_verbose.log | tail -30
    cd ..
    return 1
fi 