#!/bin/bash

# iOS Asset Download Script
# Downloads logos, splash screens, Firebase config, and other assets

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "📥 Starting iOS asset downloads..."

# Create assets directory
ASSETS_DIR="ios/Runner/Assets.xcassets"
mkdir -p "$ASSETS_DIR"

# Function to download file with error handling
download_file() {
  local url="$1"
  local output_path="$2"
  local description="$3"
  
  if [ -z "$url" ]; then
    log_warn "⚠️ $description URL is empty, skipping..."
    return 0
  fi
  
  log_info "📥 Downloading $description..."
  
  if curl -L -f -s "$url" -o "$output_path" 2>/dev/null; then
    log_success "✅ Downloaded $description to $output_path"
    return 0
  else
    log_error "❌ Failed to download $description from $url"
    return 1
  fi
}

# Download app icon/logo
if [ -n "${LOGO_URL:-}" ]; then
  download_file "$LOGO_URL" "assets/icons/app_logo.png" "app logo"
fi

# Download splash screen
if [ -n "${SPLASH_URL:-}" ]; then
  download_file "$SPLASH_URL" "assets/images/splash_screen.png" "splash screen"
fi

# Download splash background
if [ -n "${SPLASH_BG_URL:-}" ]; then
  download_file "$SPLASH_BG_URL" "assets/images/splash_background.png" "splash background"
fi

# Download Firebase configuration
if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
  log_info "🔥 Downloading Firebase configuration..."
  
  if curl -L -f -s "$FIREBASE_CONFIG_IOS" -o "ios/Runner/GoogleService-Info.plist" 2>/dev/null; then
    log_success "✅ Downloaded Firebase configuration"
  else
    log_error "❌ Failed to download Firebase configuration from $FIREBASE_CONFIG_IOS"
    # Don't fail the build for Firebase config issues
  fi
fi

# Download App Store Connect API key if needed
if [ "${IS_TESTFLIGHT:-false}" = "true" ] && [ -n "${APP_STORE_CONNECT_API_KEY:-}" ]; then
  log_info "📱 Downloading App Store Connect API key..."
  
  if curl -L -f -s "$APP_STORE_CONNECT_API_KEY" -o "AuthKey_${APP_STORE_CONNECT_KEY_IDENTIFIER:-}.p8" 2>/dev/null; then
    log_success "✅ Downloaded App Store Connect API key"
  else
    log_error "❌ Failed to download App Store Connect API key"
  fi
fi

# Download APNS key if needed
if [ -n "${APNS_AUTH_KEY_URL:-}" ]; then
  log_info "🔔 Downloading APNS key..."
  
  if curl -L -f -s "$APNS_AUTH_KEY_URL" -o "AuthKey_${APNS_KEY_ID:-}.p8" 2>/dev/null; then
    log_success "✅ Downloaded APNS key"
  else
    log_error "❌ Failed to download APNS key"
  fi
fi

# Create default assets if not downloaded
log_info "🎨 Creating default assets if needed..."

# Create default app icon if logo not downloaded
if [ ! -f "assets/icons/app_logo.png" ]; then
  log_warn "⚠️ No app logo downloaded, using default..."
  # Copy default logo if exists
  if [ -f "assets/images/default_logo.png" ]; then
    cp "assets/images/default_logo.png" "assets/icons/app_logo.png"
    log_success "✅ Copied default logo"
  fi
fi

# Create default splash screen if not downloaded
if [ ! -f "assets/images/splash_screen.png" ]; then
  log_warn "⚠️ No splash screen downloaded, using default..."
  # Copy default splash if exists
  if [ -f "assets/images/default_logo.png" ]; then
    cp "assets/images/default_logo.png" "assets/images/splash_screen.png"
    log_success "✅ Copied default splash screen"
  fi
fi

# Update iOS asset catalog if assets were downloaded
if [ -f "assets/icons/app_logo.png" ] || [ -f "assets/images/splash_screen.png" ]; then
  log_info "📱 Updating iOS asset catalog..."
  
  # Create AppIcon.appiconset if it doesn't exist
  APPICON_DIR="$ASSETS_DIR/AppIcon.appiconset"
  mkdir -p "$APPICON_DIR"
  
  # Create Contents.json for AppIcon if it doesn't exist
  if [ ! -f "$APPICON_DIR/Contents.json" ]; then
    cat > "$APPICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    log_success "✅ Created AppIcon Contents.json"
  fi
  
  # Copy app logo to AppIcon if it exists
  if [ -f "assets/icons/app_logo.png" ]; then
    cp "assets/icons/app_logo.png" "$APPICON_DIR/Icon-App-1024x1024@1x.png"
    log_success "✅ Copied app logo to AppIcon"
  fi
fi

log_success "✅ iOS asset downloads completed" 