#!/bin/bash

# Fix Podfile Deployment Target Script
# Fixes iOS deployment target and platform specification issues

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Fixing Podfile deployment target and platform issues..."

PODFILE_PATH="ios/Podfile"

if [ ! -f "$PODFILE_PATH" ]; then
    log_error "Podfile not found at $PODFILE_PATH"
    exit 1
fi

# Create backup
cp "$PODFILE_PATH" "${PODFILE_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
log_success "✅ Podfile backed up"

# Check current deployment target (including commented lines)
CURRENT_TARGET=$(grep -o "platform :ios, '[0-9.]*'" "$PODFILE_PATH" | head -1 | grep -o "[0-9.]*" || echo "12.0")
log_info "📱 Current iOS deployment target: $CURRENT_TARGET"

# Determine required deployment target for Firebase
REQUIRED_TARGET="13.0"
if [[ "$CURRENT_TARGET" < "$REQUIRED_TARGET" ]]; then
    log_info "🔄 Updating deployment target from $CURRENT_TARGET to $REQUIRED_TARGET for Firebase compatibility"
    
    # Handle commented platform line first
    if grep -q "# platform :ios" "$PODFILE_PATH"; then
        # Uncomment and update the platform line
        sed -i '' "s/# platform :ios, '[0-9.]*'/platform :ios, '$REQUIRED_TARGET'/g" "$PODFILE_PATH"
        log_success "✅ Uncommented and updated platform specification to iOS $REQUIRED_TARGET"
    elif grep -q "platform :ios" "$PODFILE_PATH"; then
        # Replace existing platform line
        sed -i '' "s/platform :ios, '[0-9.]*'/platform :ios, '$REQUIRED_TARGET'/g" "$PODFILE_PATH"
        log_success "✅ Updated platform specification to iOS $REQUIRED_TARGET"
    else
        # Add platform specification if missing
        sed -i '' "1i\\
platform :ios, '$REQUIRED_TARGET'
" "$PODFILE_PATH"
        log_success "✅ Added platform specification: iOS $REQUIRED_TARGET"
    fi
else
    log_info "✅ Deployment target $CURRENT_TARGET is already sufficient"
fi

# Check and fix post_install hook for deployment target
if grep -q "post_install" "$PODFILE_PATH"; then
    log_info "🔧 Updating post_install hook deployment target..."
    
    # Check if IPHONEOS_DEPLOYMENT_TARGET is already set in post_install
    if grep -q "IPHONEOS_DEPLOYMENT_TARGET" "$PODFILE_PATH"; then
        # Update existing deployment target
        sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = '[0-9.]*'/IPHONEOS_DEPLOYMENT_TARGET = '$REQUIRED_TARGET'/g" "$PODFILE_PATH"
        log_success "✅ Updated post_install deployment target to $REQUIRED_TARGET"
    else
        # Add deployment target to existing post_install hook
        awk -v target="$REQUIRED_TARGET" '/flutter_additional_ios_build_settings\(target\)/ { print; print "      target.build_configurations.each do |config|"; print "        config.build_settings[\"IPHONEOS_DEPLOYMENT_TARGET\"] = \"" target "\""; print "        config.build_settings[\"ENABLE_BITCODE\"] = \"NO\""; print "        config.build_settings[\"EXCLUDED_ARCHS[sdk=iphonesimulator*]\"] = \"arm64\""; print "      end"; next } { print }' "$PODFILE_PATH" > "${PODFILE_PATH}.tmp" && mv "${PODFILE_PATH}.tmp" "$PODFILE_PATH"
        log_success "✅ Added deployment target settings to existing post_install hook"
    fi
else
    log_warn "⚠️ No post_install hook found, adding one..."
    
    # Add post_install hook at the end of the file
    cat >> "$PODFILE_PATH" << 'EOF'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
EOF
    log_success "✅ Added post_install hook with deployment target $REQUIRED_TARGET"
fi

# Check for use_frameworks!
if ! grep -q "use_frameworks!" "$PODFILE_PATH"; then
    log_warn "⚠️ use_frameworks! not found, adding it..."
    
    # Add use_frameworks! after platform specification
    sed -i '' "/platform :ios/a\\
use_frameworks!
" "$PODFILE_PATH"
    log_success "✅ Added use_frameworks!"
fi

# Check for target 'Runner'
if ! grep -q "target 'Runner'" "$PODFILE_PATH"; then
    log_error "❌ Target 'Runner' not found in Podfile"
    exit 1
fi

# Validate the updated Podfile
log_info "🔍 Validating updated Podfile..."
if grep -q "platform :ios, '$REQUIRED_TARGET'" "$PODFILE_PATH"; then
    log_success "✅ Platform specification updated correctly"
else
    log_error "❌ Failed to update platform specification"
    exit 1
fi

if grep -q "IPHONEOS_DEPLOYMENT_TARGET.*=.*'$REQUIRED_TARGET'" "$PODFILE_PATH" || grep -q "IPHONEOS_DEPLOYMENT_TARGET.*=.*\"$REQUIRED_TARGET\"" "$PODFILE_PATH"; then
    log_success "✅ Deployment target updated correctly"
else
    log_error "❌ Failed to update deployment target"
    exit 1
fi

log_success "✅ Podfile deployment target fix completed"
log_info "📱 Updated to iOS $REQUIRED_TARGET for Firebase compatibility"

# Show the updated Podfile structure
log_info "📋 Updated Podfile structure:"
head -20 "$PODFILE_PATH" 