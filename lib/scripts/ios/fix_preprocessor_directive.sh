#!/bin/bash

# Fix Preprocessor Directive Script
# Fixes the "unsupported preprocessor directive 'Production'" error

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Fixing preprocessor directive issue..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
  log_error "❌ pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Function to check and fix xcconfig files
fix_xcconfig_files() {
  log_info "📱 Checking xcconfig files..."
  
  XCCONFIG_FILES=(
    "ios/Flutter/Debug.xcconfig"
    "ios/Flutter/Release.xcconfig"
    "ios/Flutter/Generated.xcconfig"
  )
  
  for file in "${XCCONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
      log_info "🔍 Checking $file..."
      
      # Check for invalid preprocessor directives
      if grep -q "^[[:space:]]*#[[:space:]]*[A-Z]" "$file"; then
        log_warn "⚠️ Found potential invalid preprocessor directive in $file"
        
        # Show the problematic lines
        log_info "📋 Problematic lines in $file:"
        grep -n "^[[:space:]]*#[[:space:]]*[A-Z]" "$file" || true
        
        # Fix by commenting out invalid directives
        sed -i '' 's/^[[:space:]]*#[[:space:]]*\([A-Z][A-Za-z]*\)[[:space:]]*$/\/\/ \1/g' "$file"
        log_success "✅ Fixed invalid preprocessor directives in $file"
      else
        log_success "✅ $file looks good"
      fi
    else
      log_warn "⚠️ $file not found"
    fi
  done
}

# Function to check and fix project.pbxproj
fix_project_pbxproj() {
  log_info "📱 Checking project.pbxproj..."
  
  if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    log_info "🔍 Checking for invalid preprocessor directives in project.pbxproj..."
    
    # Check for invalid preprocessor directives
    if grep -q "^[[:space:]]*#[[:space:]]*[A-Z]" "ios/Runner.xcodeproj/project.pbxproj"; then
      log_warn "⚠️ Found potential invalid preprocessor directive in project.pbxproj"
      
      # Show the problematic lines
      log_info "📋 Problematic lines in project.pbxproj:"
      grep -n "^[[:space:]]*#[[:space:]]*[A-Z]" "ios/Runner.xcodeproj/project.pbxproj" || true
      
      # Fix by commenting out invalid directives
      sed -i '' 's/^[[:space:]]*#[[:space:]]*\([A-Z][A-Za-z]*\)[[:space:]]*$/\/\/ \1/g' "ios/Runner.xcodeproj/project.pbxproj"
      log_success "✅ Fixed invalid preprocessor directives in project.pbxproj"
    else
      log_success "✅ project.pbxproj looks good"
    fi
  else
    log_error "❌ project.pbxproj not found"
  fi
}

# Function to check and fix Podfile
fix_podfile() {
  log_info "📱 Checking Podfile..."
  
  if [ -f "ios/Podfile" ]; then
    log_info "🔍 Checking for invalid preprocessor directives in Podfile..."
    
    # Check for invalid preprocessor directives (only lines that start with # followed by a capital letter)
    # This excludes valid comments like "# Uncomment this line" or "# CocoaPods analytics"
    if grep -q "^[[:space:]]*#[[:space:]]*[A-Z][A-Za-z]*[[:space:]]*$" "ios/Podfile"; then
      log_warn "⚠️ Found potential invalid preprocessor directive in Podfile"
      
      # Show the problematic lines
      log_info "📋 Problematic lines in Podfile:"
      grep -n "^[[:space:]]*#[[:space:]]*[A-Z][A-Za-z]*[[:space:]]*$" "ios/Podfile" || true
      
      # Fix by commenting out invalid directives
      sed -i '' 's/^[[:space:]]*#[[:space:]]*\([A-Z][A-Za-z]*\)[[:space:]]*$/\/\/ \1/g' "ios/Podfile"
      log_success "✅ Fixed invalid preprocessor directives in Podfile"
    else
      log_success "✅ Podfile looks good"
    fi
  else
    log_error "❌ Podfile not found"
  fi
}

# Function to clean and regenerate Flutter files
regenerate_flutter_files() {
  log_info "🔄 Regenerating Flutter files..."
  
  # Clean Flutter
  flutter clean 2>/dev/null || true
  
  # Get Flutter dependencies
  flutter pub get
  
  # Check if Generated.xcconfig was regenerated
  if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    log_success "✅ Flutter files regenerated"
  else
    log_error "❌ Failed to regenerate Flutter files"
    return 1
  fi
}

# Function to check for any remaining issues
check_remaining_issues() {
  log_info "🔍 Checking for remaining issues..."
  
  # Check for any remaining invalid preprocessor directives (only standalone directives, not comments)
  INVALID_DIRECTIVES=$(find ios -name "*.xcconfig" -o -name "*.pbxproj" -o -name "Podfile" | xargs grep -l "^[[:space:]]*#[[:space:]]*[A-Z][A-Za-z]*[[:space:]]*$" 2>/dev/null || true)
  
  if [ ! -z "$INVALID_DIRECTIVES" ]; then
    log_warn "⚠️ Found remaining invalid preprocessor directives in:"
    echo "$INVALID_DIRECTIVES"
    return 1
  else
    log_success "✅ No remaining invalid preprocessor directives found"
    return 0
  fi
}

# Main execution
echo "🔧 Running preprocessor directive fix..."

# Run all fixes
if fix_xcconfig_files && fix_project_pbxproj && fix_podfile && regenerate_flutter_files && check_remaining_issues; then
  log_success "🎉 Preprocessor directive fix completed successfully!"
  log_info "📋 You can now try building again"
else
  log_error "❌ Preprocessor directive fix failed"
  exit 1
fi 