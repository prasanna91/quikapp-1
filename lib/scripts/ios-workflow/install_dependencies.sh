#!/bin/bash

# Install Dependencies Script
# Installs missing dependencies for iOS workflow

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Installing iOS Workflow Dependencies..."

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  log_info "📦 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log_success "✅ Homebrew installed"
else
  log_success "✅ Homebrew already installed"
fi

# Install CocoaPods
if ! command -v pod &>/dev/null; then
  log_info "📦 Installing CocoaPods..."
  
  # Try Homebrew first
  if brew install cocoapods 2>/dev/null; then
    log_success "✅ CocoaPods installed via Homebrew"
  else
    log_warn "⚠️ Homebrew installation failed, trying gem..."
    
    # Try gem installation
    if sudo gem install cocoapods 2>/dev/null; then
      log_success "✅ CocoaPods installed via gem"
    else
      log_error "❌ Failed to install CocoaPods"
      log_info "📋 Manual installation required:"
      log_info "   Visit: https://cocoapods.org/#install"
      exit 1
    fi
  fi
else
  log_success "✅ CocoaPods already installed: $(pod --version)"
fi

# Check for keychain command (Codemagic CLI)
if ! command -v keychain &>/dev/null; then
  log_warn "⚠️ keychain command not available"
  log_info "📋 This is normal in local development environments"
  log_info "📋 The script will use alternative methods for certificate management"
else
  log_success "✅ keychain command available"
fi

# Check for xcode-project command
if ! command -v xcode-project &>/dev/null; then
  log_warn "⚠️ xcode-project command not available"
  log_info "📋 This is normal in local development environments"
  log_info "📋 The script will continue without Xcode project modifications"
else
  log_success "✅ xcode-project command available"
fi

# Verify Flutter installation
if command -v flutter &>/dev/null; then
  log_success "✅ Flutter installed: $(flutter --version | head -1)"
else
  log_error "❌ Flutter not installed"
  log_info "📋 Install Flutter from: https://flutter.dev/docs/get-started/install"
  exit 1
fi

# Verify Xcode installation
if command -v xcodebuild &>/dev/null; then
  log_success "✅ Xcode installed: $(xcodebuild -version | head -1)"
else
  log_error "❌ Xcode not installed"
  log_info "📋 Install Xcode from the App Store"
  exit 1
fi

log_success "🎉 All dependencies installed successfully!"
log_info "📋 Ready to run: ./lib/scripts/ios-workflow/simple_ios_build.sh" 