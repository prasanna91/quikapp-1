#!/bin/bash

# iOS Workflow Fix Script
# Fixes common issues with iOS workflow including Firebase deployment target

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Fixing iOS workflow issues..."

# 1. Fix Podfile deployment target for Firebase
log_info "📱 Fixing Podfile deployment target for Firebase compatibility..."
if [ -f "lib/scripts/ios/fix_podfile_deployment_target.sh" ]; then
  chmod +x lib/scripts/ios/fix_podfile_deployment_target.sh
  if ./lib/scripts/ios/fix_podfile_deployment_target.sh; then
    log_success "✅ Podfile deployment target fixed"
  else
    log_error "❌ Podfile deployment target fix failed"
    exit 1
  fi
else
  log_warn "⚠️ Podfile fix script not found, attempting manual fix..."
  
  # Manual Podfile fix
  PODFILE_PATH="ios/Podfile"
  if [ -f "$PODFILE_PATH" ]; then
    # Update platform specification to iOS 13.0
    if grep -q "platform :ios" "$PODFILE_PATH"; then
      sed -i '' "s/platform :ios, '[0-9.]*'/platform :ios, '13.0'/g" "$PODFILE_PATH"
      log_success "✅ Updated platform specification to iOS 13.0"
    else
      # Add platform specification if missing
      sed -i '' "1i\\
platform :ios, '13.0'
" "$PODFILE_PATH"
      log_success "✅ Added platform specification: iOS 13.0"
    fi
    
    # Update post_install deployment target
    if grep -q "post_install" "$PODFILE_PATH"; then
      sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = '[0-9.]*'/IPHONEOS_DEPLOYMENT_TARGET = '13.0'/g" "$PODFILE_PATH"
      log_success "✅ Updated post_install deployment target to 13.0"
    else
      # Add post_install hook if missing
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
      log_success "✅ Added post_install hook with deployment target 13.0"
    fi
  else
    log_error "❌ Podfile not found"
    exit 1
  fi
fi

# 2. Validate environment variables
log_info "🔍 Validating environment variables..."
if [ -f "lib/scripts/ios-workflow/validate_environment.sh" ]; then
  chmod +x lib/scripts/ios-workflow/validate_environment.sh
  if ./lib/scripts/ios-workflow/validate_environment.sh; then
    log_success "✅ Environment validation passed"
  else
    log_error "❌ Environment validation failed"
    exit 1
  fi
else
  log_warn "⚠️ Environment validation script not found, performing basic checks..."
  
  # Basic environment variable checks
  REQUIRED_VARS=("APP_NAME" "APP_DISPLAY_NAME" "BUNDLE_ID" "VERSION_NAME" "VERSION_CODE")
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      log_error "❌ Missing required variable: $var"
      exit 1
    fi
  done
  log_success "✅ Basic environment validation passed"
fi

# 3. Download assets
log_info "📥 Downloading assets..."
if [ -f "lib/scripts/ios/download_assets.sh" ]; then
  chmod +x lib/scripts/ios/download_assets.sh
  if ./lib/scripts/ios/download_assets.sh; then
    log_success "✅ Assets downloaded successfully"
  else
    log_warn "⚠️ Asset download had issues, but continuing..."
  fi
else
  log_warn "⚠️ Asset download script not found, skipping..."
fi

# 4. Fix iOS project configuration
log_info "🔧 Fixing iOS project configuration..."

# Update bundle identifier in project files
OLD_BUNDLE_ID="com.example.sampleprojects.sampleProject"
NEW_BUNDLE_ID="${BUNDLE_ID:-com.garbcode.garbcodeapp}"

if [ -d "ios" ]; then
  # Update in project.pbxproj
  find ios -name "project.pbxproj" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \; 2>/dev/null || true
  
  # Update in Info.plist
  find ios -name "Info.plist" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \; 2>/dev/null || true
  
  # Update in entitlements files
  find ios -name "*.entitlements" -exec sed -i '' "s/$OLD_BUNDLE_ID/$NEW_BUNDLE_ID/g" {} \; 2>/dev/null || true
  
  log_success "✅ Bundle identifier updated to $NEW_BUNDLE_ID"
fi

# 5. Update Info.plist with app display name
PLIST_PATH="ios/Runner/Info.plist"
DISPLAY_NAME="${APP_DISPLAY_NAME:-Runner}"

if [ -f "$PLIST_PATH" ]; then
  # Check if key exists, else add it
  if /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST_PATH" 2>/dev/null; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$DISPLAY_NAME'" "$PLIST_PATH"
  else
    /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string '$DISPLAY_NAME'" "$PLIST_PATH"
  fi
  log_success "✅ Updated app display name to: $DISPLAY_NAME"
fi

# 6. Fix release.xcconfig for code signing
XC_CONFIG_PATH="ios/Flutter/release.xcconfig"
if [ -f "$XC_CONFIG_PATH" ]; then
  log_info "🔧 Updating release.xcconfig..."
  
  # Remove any previous entries for these keys to avoid duplicates
  sed -i '' '/^CODE_SIGN_STYLE/d' "$XC_CONFIG_PATH" 2>/dev/null || true
  sed -i '' '/^DEVELOPMENT_TEAM/d' "$XC_CONFIG_PATH" 2>/dev/null || true
  sed -i '' '/^PROVISIONING_PROFILE_SPECIFIER/d' "$XC_CONFIG_PATH" 2>/dev/null || true
  sed -i '' '/^CODE_SIGN_IDENTITY/d' "$XC_CONFIG_PATH" 2>/dev/null || true
  sed -i '' '/^PRODUCT_BUNDLE_IDENTIFIER/d' "$XC_CONFIG_PATH" 2>/dev/null || true
  
  # Append updated values
  {
    echo "CODE_SIGN_STYLE = ${CODE_SIGNING_STYLE:-manual}"
    echo "DEVELOPMENT_TEAM = ${APPLE_TEAM_ID:-}"
    echo "PROVISIONING_PROFILE_SPECIFIER = ${PROFILE_SPECIFIER_UUID:-}"
    echo "CODE_SIGN_IDENTITY = ${CM_DISTRIBUTION_TYPE:-Apple Distribution}"
    echo "PRODUCT_BUNDLE_IDENTIFIER = $NEW_BUNDLE_ID"
  } >> "$XC_CONFIG_PATH"
  
  log_success "✅ Updated release.xcconfig"
fi

# 7. Ensure CocoaPods is properly configured
log_info "📦 Ensuring CocoaPods configuration..."
if [ -f "ios/Podfile" ]; then
  # Check if use_frameworks! is present
  if ! grep -q "use_frameworks!" "ios/Podfile"; then
    # Add use_frameworks! after platform specification
    sed -i '' "/platform :ios/a\\
use_frameworks!
" "ios/Podfile"
    log_success "✅ Added use_frameworks! to Podfile"
  fi
  
  # Check if target 'Runner' is present
  if ! grep -q "target 'Runner'" "ios/Podfile"; then
    log_error "❌ Target 'Runner' not found in Podfile"
    exit 1
  fi
fi

# 8. Clean and prepare for build
log_info "🧹 Cleaning previous builds..."
flutter clean 2>/dev/null || true
rm -rf ios/build/ 2>/dev/null || true
rm -rf ios/Pods/ 2>/dev/null || true

# 9. Install Flutter dependencies
log_info "📦 Installing Flutter dependencies..."
if flutter pub get; then
  log_success "✅ Flutter dependencies installed"
else
  log_error "❌ Flutter dependencies installation failed"
  exit 1
fi

# 10. Install CocoaPods
log_info "📦 Installing CocoaPods..."
if [ -f "ios/Podfile" ]; then
  cd ios
  if pod install; then
    log_success "✅ CocoaPods installed successfully"
  else
    log_error "❌ CocoaPods installation failed"
    cd ..
    exit 1
  fi
  cd ..
else
  log_error "❌ Podfile not found"
  exit 1
fi

log_success "✅ iOS workflow issues fixed successfully" 