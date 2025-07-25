#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"; }
handle_error() { log "ERROR: Command '$BASH_COMMAND' failed at line $LINENO"; exit 1; }
trap 'handle_error' ERR

# Branding vars
LOGO_URL=${LOGO_URL:-}
SPLASH_URL=${SPLASH_URL:-}
SPLASH_BG_URL=${SPLASH_BG_URL:-}
SPLASH_BG_COLOR=${SPLASH_BG_COLOR:-}
SPLASH_TAGLINE=${SPLASH_TAGLINE:-}
SPLASH_TAGLINE_COLOR=${SPLASH_TAGLINE_COLOR:-}
SPLASH_ANIMATION=${SPLASH_ANIMATION:-}
SPLASH_DURATION=${SPLASH_DURATION:-}

log "Starting branding process for $APP_NAME (iOS)"

# Ensure directories exist silently
mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset \
         ios/Runner/Assets.xcassets/Splash.imageset \
         ios/Runner/Assets.xcassets/SplashBackground.imageset \
         assets/images

# Function to download asset with validation (silent curl)
download_asset() {
    local url="$1"
    local output="$2"
    local name="$3"
    local fallback="$4"

    if [ -n "$url" ]; then
        if curl -L --fail --silent --show-error --output "$output" "$url" 2>/dev/null; then
            if [ -f "$output" ] && [ -s "$output" ]; then
                log "✅ $name downloaded successfully"
                return 0
            else
                log "⚠️ $name download failed - empty file"
            fi
        else
            log "⚠️ Failed to download $name from $url"
        fi
    fi

    if [ -n "$fallback" ] && [ -f "$fallback" ]; then
        cp "$fallback" "$output"
        log "⚠️ Using fallback $name"
        return 0
    fi

    return 1
}

# Download logo
if [ -n "$LOGO_URL" ]; then
    if ! download_asset "$LOGO_URL" "assets/images/logo.png" "logo" ""; then
        log "⚠️ Failed to download logo, creating placeholder"
        echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > assets/images/logo.png 2>/dev/null || {
            printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf5\xd7\xd4\xc2\x00\x00\x00\x00IEND\xaeB`\x82' > assets/images/logo.png
        }
    fi
else
    log "LOGO_URL is empty, creating placeholder logo"
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > assets/images/logo.png 2>/dev/null || {
        printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf5\xd7\xd4\xc2\x00\x00\x00\x00IEND\xaeB`\x82' > assets/images/logo.png
    }
fi

# Copy logo to iOS AppIcon silently
if [ -f "assets/images/logo.png" ]; then
    cp assets/images/logo.png ios/Runner/Assets.xcassets/AppIcon.appiconset/logo.png
    log "✅ Logo copied to iOS AppIcon"
fi

# Download splash image or fallback to logo silently
if [ -n "$SPLASH_URL" ]; then
    if ! download_asset "$SPLASH_URL" "assets/images/splash.png" "splash image" "assets/images/logo.png"; then
        log "⚠️ Failed to download splash image, using logo as splash"
        cp assets/images/logo.png assets/images/splash.png
    fi
else
    log "SPLASH_URL is empty, using logo as splash image"
    cp assets/images/logo.png assets/images/splash.png
fi

# Copy splash image silently
if [ -f "assets/images/splash.png" ]; then
    cp assets/images/splash.png ios/Runner/Assets.xcassets/Splash.imageset/splash.png
    log "✅ Splash image copied to iOS Splash.imageset"
fi

# Download splash background (optional) silently
if [ -n "$SPLASH_BG_URL" ]; then
    if download_asset "$SPLASH_BG_URL" "assets/images/splash_bg.png" "splash background" ""; then
        cp assets/images/splash_bg.png ios/Runner/Assets.xcassets/SplashBackground.imageset/splash_bg.png
        log "✅ Splash background copied to iOS SplashBackground.imageset"
    else
        log "⚠️ Failed to download splash background, skipping"
    fi
else
    log "SPLASH_BG_URL is empty, skipping splash background"
fi

# Verify assets silently
log "Verifying required assets..."
required_assets=("assets/images/logo.png" "assets/images/splash.png")
for asset in "${required_assets[@]}"; do
    if [ -f "$asset" ] && [ -s "$asset" ]; then
        log "✅ $asset exists and has content"
    else
        log "❌ $asset is missing or empty"
        exit 1
    fi
done

log "Branding process completed successfully (iOS)"
exit 0
