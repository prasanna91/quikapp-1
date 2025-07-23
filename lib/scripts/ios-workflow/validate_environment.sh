#!/bin/bash

# iOS Workflow Environment Validation Script
# Validates all required environment variables for iOS build

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔍 Validating iOS workflow environment variables..."

# Required variables for iOS build
REQUIRED_VARS=(
  "APP_NAME"
  "APP_DISPLAY_NAME"
  "BUNDLE_ID"
  "VERSION_NAME"
  "VERSION_CODE"
  "PROFILE_SPECIFIER_UUID"
  "CM_PROVISIONING_PROFILE"
  "CM_CERTIFICATE"
  "CM_CERTIFICATE_PASSWORD"
  "APPLE_TEAM_ID"
  "CM_DISTRIBUTION_TYPE"
)

# Optional but recommended variables
RECOMMENDED_VARS=(
  "LOGO_URL"
  "SPLASH_URL"
  "FIREBASE_CONFIG_IOS"
  "ENABLE_EMAIL_NOTIFICATIONS"
  "EMAIL_SMTP_SERVER"
  "EMAIL_SMTP_USER"
  "EMAIL_SMTP_PASS"
)

# App Store Connect variables (if using TestFlight)
APP_STORE_VARS=(
  "APP_STORE_CONNECT_KEY_IDENTIFIER"
  "APP_STORE_CONNECT_API_KEY"
  "APP_STORE_CONNECT_ISSUER_ID"
)

# Check required variables
log_info "📋 Checking required variables..."
MISSING_REQUIRED=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING_REQUIRED+=("$var")
    log_error "❌ Missing required variable: $var"
  else
    log_success "✅ $var is set"
  fi
done

# Check recommended variables
log_info "📋 Checking recommended variables..."
MISSING_RECOMMENDED=()
for var in "${RECOMMENDED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    MISSING_RECOMMENDED+=("$var")
    log_warn "⚠️ Missing recommended variable: $var"
  else
    log_success "✅ $var is set"
  fi
done

# Check App Store Connect variables if IS_TESTFLIGHT is true
if [ "${IS_TESTFLIGHT:-false}" = "true" ]; then
  log_info "📋 Checking App Store Connect variables for TestFlight..."
  MISSING_APP_STORE=()
  for var in "${APP_STORE_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      MISSING_APP_STORE+=("$var")
      log_error "❌ Missing App Store Connect variable: $var (required for TestFlight)"
    else
      log_success "✅ $var is set"
    fi
  done
fi

# Validate specific variable formats
log_info "🔍 Validating variable formats..."

# Check bundle ID format
if [[ "${BUNDLE_ID:-}" =~ ^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$ ]]; then
  log_success "✅ BUNDLE_ID format is valid: ${BUNDLE_ID}"
else
  log_error "❌ BUNDLE_ID format is invalid: ${BUNDLE_ID:-not set}"
fi

# Check version format
if [[ "${VERSION_NAME:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_success "✅ VERSION_NAME format is valid: ${VERSION_NAME}"
else
  log_warn "⚠️ VERSION_NAME format might be invalid: ${VERSION_NAME:-not set}"
fi

if [[ "${VERSION_CODE:-}" =~ ^[0-9]+$ ]]; then
  log_success "✅ VERSION_CODE format is valid: ${VERSION_CODE}"
else
  log_error "❌ VERSION_CODE format is invalid: ${VERSION_CODE:-not set}"
fi

# Check Apple Team ID format
if [[ "${APPLE_TEAM_ID:-}" =~ ^[A-Z0-9]{10}$ ]]; then
  log_success "✅ APPLE_TEAM_ID format is valid: ${APPLE_TEAM_ID}"
else
  log_error "❌ APPLE_TEAM_ID format is invalid: ${APPLE_TEAM_ID:-not set}"
fi

# Check certificate and profile
if [ -n "${CM_CERTIFICATE:-}" ]; then
  log_success "✅ CM_CERTIFICATE is set"
else
  log_error "❌ CM_CERTIFICATE is not set"
fi

if [ -n "${CM_PROVISIONING_PROFILE:-}" ]; then
  log_success "✅ CM_PROVISIONING_PROFILE is set"
else
  log_error "❌ CM_PROVISIONING_PROFILE is not set"
fi

# Check Firebase configuration
if [ -n "${FIREBASE_CONFIG_IOS:-}" ]; then
  log_success "✅ FIREBASE_CONFIG_IOS is set"
else
  log_warn "⚠️ FIREBASE_CONFIG_IOS is not set (Firebase features may not work)"
fi

# Check email configuration
if [ "${ENABLE_EMAIL_NOTIFICATIONS:-false}" = "true" ]; then
  if [ -n "${EMAIL_SMTP_SERVER:-}" ] && [ -n "${EMAIL_SMTP_USER:-}" ] && [ -n "${EMAIL_SMTP_PASS:-}" ]; then
    log_success "✅ Email notification configuration is complete"
  else
    log_warn "⚠️ Email notifications enabled but configuration is incomplete"
  fi
fi

# Summary
echo ""
log_info "📊 Environment Validation Summary:"

if [ ${#MISSING_REQUIRED[@]} -eq 0 ]; then
  log_success "✅ All required variables are set"
else
  log_error "❌ Missing ${#MISSING_REQUIRED[@]} required variables:"
  for var in "${MISSING_REQUIRED[@]}"; do
    echo "   - $var"
  done
fi

if [ ${#MISSING_RECOMMENDED[@]} -gt 0 ]; then
  log_warn "⚠️ Missing ${#MISSING_RECOMMENDED[@]} recommended variables:"
  for var in "${MISSING_RECOMMENDED[@]}"; do
    echo "   - $var"
  done
fi

if [ "${IS_TESTFLIGHT:-false}" = "true" ] && [ ${#MISSING_APP_STORE[@]} -gt 0 ]; then
  log_error "❌ Missing ${#MISSING_APP_STORE[@]} App Store Connect variables for TestFlight:"
  for var in "${MISSING_APP_STORE[@]}"; do
    echo "   - $var"
  done
fi

# Exit with error if required variables are missing
if [ ${#MISSING_REQUIRED[@]} -gt 0 ]; then
  log_error "❌ Environment validation failed - missing required variables"
  exit 1
fi

if [ "${IS_TESTFLIGHT:-false}" = "true" ] && [ ${#MISSING_APP_STORE[@]} -gt 0 ]; then
  log_error "❌ Environment validation failed - missing App Store Connect variables for TestFlight"
  exit 1
fi

log_success "✅ Environment validation completed successfully" 