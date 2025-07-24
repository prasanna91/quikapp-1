#!/bin/bash

# Setup Environment Variables Script
# Handles environment variable setup for iOS builds

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Setting up environment variables..."

# Set default values for required variables
UUID="${UUID:-}"
BUNDLE_ID="${BUNDLE_ID:-}"
CM_DISTRIBUTION_TYPE="${CM_DISTRIBUTION_TYPE:-Apple Distribution}"
CODE_SIGNING_STYLE="${CODE_SIGNING_STYLE:-manual}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"

# If UUID or BUNDLE_ID are not set, try to extract from provisioning profile
if [ -z "$UUID" ] || [ -z "$BUNDLE_ID" ]; then
  log_info "📋 Extracting UUID and BUNDLE_ID from provisioning profile..."
  
  # Find the provisioning profile
  PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
  if [ -d "$PROFILES_HOME" ]; then
    PROFILE_PATH=$(find "$PROFILES_HOME" -name "*.mobileprovision" | head -n 1)
    
    if [ ! -z "$PROFILE_PATH" ] && [ -f "$PROFILE_PATH" ]; then
      log_info "📋 Found provisioning profile: $PROFILE_PATH"
      
      # Extract UUID and Bundle ID from provisioning profile
      security cms -D -i "$PROFILE_PATH" > /tmp/profile.plist
      
      if [ -f "/tmp/profile.plist" ]; then
        UUID=$(/usr/libexec/PlistBuddy -c "Print UUID" /tmp/profile.plist 2>/dev/null || echo "")
        BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :Entitlements:application-identifier" /tmp/profile.plist 2>/dev/null | cut -d '.' -f 2- || echo "")
        
        if [ ! -z "$UUID" ]; then
          log_success "✅ Extracted UUID: $UUID"
        else
          log_warn "⚠️ Could not extract UUID from provisioning profile"
        fi
        
        if [ ! -z "$BUNDLE_ID" ]; then
          log_success "✅ Extracted BUNDLE_ID: $BUNDLE_ID"
        else
          log_warn "⚠️ Could not extract BUNDLE_ID from provisioning profile"
        fi
      else
        log_warn "⚠️ Could not decode provisioning profile"
      fi
    else
      log_warn "⚠️ No provisioning profile found"
    fi
  else
    log_warn "⚠️ Provisioning profiles directory not found"
  fi
fi

# Validate required variables
if [ -z "$UUID" ]; then
  log_error "❌ UUID is not set and could not be extracted from provisioning profile"
  log_info "📋 Please ensure UUID environment variable is set or provisioning profile is available"
  exit 1
fi

if [ -z "$BUNDLE_ID" ]; then
  log_error "❌ BUNDLE_ID is not set and could not be extracted from provisioning profile"
  log_info "📋 Please ensure BUNDLE_ID environment variable is set or provisioning profile is available"
  exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
  log_warn "⚠️ APPLE_TEAM_ID is not set"
  log_info "📋 This may cause issues with code signing"
fi

log_success "✅ Environment variables configured:"
log_info "   UUID: $UUID"
log_info "   BUNDLE_ID: $BUNDLE_ID"
log_info "   CM_DISTRIBUTION_TYPE: $CM_DISTRIBUTION_TYPE"
log_info "   CODE_SIGNING_STYLE: $CODE_SIGNING_STYLE"
log_info "   APPLE_TEAM_ID: $APPLE_TEAM_ID"

# Export variables for use in other scripts
export UUID
export BUNDLE_ID
export CM_DISTRIBUTION_TYPE
export CODE_SIGNING_STYLE
export APPLE_TEAM_ID

log_success "🎉 Environment variables setup completed successfully!" 