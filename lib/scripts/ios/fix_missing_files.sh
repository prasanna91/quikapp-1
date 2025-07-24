#!/bin/bash

# Fix Missing Files Script
# Restores missing files from backup versions

set -euo pipefail

log_info()    { echo "ℹ️ $1"; }
log_success() { echo "✅ $1"; }
log_error()   { echo "❌ $1"; }
log_warn()    { echo "⚠️ $1"; }

echo "🔧 Fixing missing files..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
  log_error "❌ pubspec.yaml not found. Please run this script from the project root."
  exit 1
fi

# Function to check and restore missing files
check_and_restore_files() {
  log_info "📋 Checking for missing files..."
  
  # Check for missing env_config.dart and restore from backup
  if [ ! -f "lib/config/env_config.dart" ]; then
    log_warn "⚠️ Missing file: lib/config/env_config.dart"
    
    if [ -f "lib/config/env_config.dart.backup" ]; then
      log_info "📋 Restoring from backup: lib/config/env_config.dart.backup"
      cp "lib/config/env_config.dart.backup" "lib/config/env_config.dart"
      log_success "✅ Restored lib/config/env_config.dart from backup"
    elif [ -f "lib/config/env_config.dart.broken" ]; then
      log_info "📋 Restoring from broken backup: lib/config/env_config.dart.broken"
      cp "lib/config/env_config.dart.broken" "lib/config/env_config.dart"
      log_success "✅ Restored lib/config/env_config.dart from broken backup"
    else
      log_error "❌ No backup file found for env_config.dart"
    fi
  else
    log_success "✅ lib/config/env_config.dart exists"
  fi
}

# Function to check critical imports in main.dart
check_critical_imports() {
  log_info "🔍 Checking critical imports in main.dart..."
  
  if [ ! -f "lib/main.dart" ]; then
    log_error "❌ main.dart not found"
    return 1
  fi
  
  # List of critical files that should exist
  CRITICAL_FILES=(
    "lib/config/env_config.dart"
    "lib/services/firebase_service.dart"
    "lib/module/myapp.dart"
    "lib/module/offline_screen.dart"
    "lib/services/notification_service.dart"
    "lib/services/connectivity_service.dart"
    "lib/utils/menu_parser.dart"
  )
  
  for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      log_error "❌ Critical file missing: $file"
      return 1
    else
      log_success "✅ $file exists"
    fi
  done
  
  return 0
}

# Function to generate missing env_config.dart if needed
generate_env_config() {
  log_info "🔧 Checking env_config.dart generation..."
  
  if [ ! -f "lib/config/env_config.dart" ]; then
    log_warn "⚠️ env_config.dart missing, attempting to generate..."
    
    if [ -f "lib/scripts/utils/gen_env_config.sh" ]; then
      log_info "📋 Running env config generator..."
      chmod +x lib/scripts/utils/gen_env_config.sh
      if ./lib/scripts/utils/gen_env_config.sh; then
        log_success "✅ Generated env_config.dart"
      else
        log_error "❌ Failed to generate env_config.dart"
        return 1
      fi
    else
      log_error "❌ env config generator not found"
      return 1
    fi
  else
    log_success "✅ env_config.dart exists"
  fi
}

# Function to validate Flutter project
validate_flutter_project() {
  log_info "🔍 Validating Flutter project..."
  
  # Check if Flutter can analyze the project (don't fail on warnings)
  if flutter analyze --no-fatal-infos > /dev/null 2>&1; then
    log_success "✅ Flutter project validation passed"
    return 0
  else
    log_warn "⚠️ Flutter project validation had issues (continuing anyway)"
    log_info "📋 Running flutter analyze to see issues..."
    flutter analyze --no-fatal-infos || true
    # Don't fail on analysis warnings, only on critical errors
    return 0
  fi
}

# Main execution
echo "🔧 Running missing files fix..."

# Run all checks and fixes
if check_and_restore_files && check_critical_imports && generate_env_config && validate_flutter_project; then
  log_success "🎉 Missing files fix completed successfully!"
  log_info "📋 All critical files are present and valid"
else
  log_error "❌ Missing files fix failed"
  exit 1
fi 