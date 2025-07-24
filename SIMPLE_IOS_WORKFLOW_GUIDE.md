# Simple iOS Workflow Guide

## Overview

The iOS workflow has been completely rewritten to be simple, direct, and reliable - following the pattern from `akash_build.sh`. The complex multi-layered scripts have been replaced with straightforward, single-purpose scripts.

## Key Changes

### ❌ **Removed Complex Components**
- Multiple fix scripts with complex dependencies
- Over-engineered error handling
- Complex script orchestration
- Multiple fallback mechanisms
- Email notification system
- Diagnostic scripts

### ✅ **New Simple Components**
- **`pre-build.sh`** - Direct pre-build setup
- **`build.sh`** - Simple build process
- **`post-build.sh`** - Basic post-build cleanup
- **`test_simple_workflow.sh`** - Workflow verification

## Script Comparison

### Before (Complex)
```bash
# Multiple layers of abstraction
pre-build.sh → fix_workflow_issues.sh → comprehensive_ios_fix.sh → multiple_fix_scripts.sh
build.sh → enhanced_build.sh → diagnose_build_issues.sh → fallback_scripts.sh
```

### After (Simple)
```bash
# Direct execution
pre-build.sh → Direct setup
build.sh → Direct build
post-build.sh → Direct cleanup
```

## Script Details

### 1. **`pre-build.sh`** - Pre-Build Setup
**Purpose**: Setup environment, certificates, and dependencies

**Key Features**:
- Environment cleanup
- Keychain initialization
- Provisioning profile setup
- Certificate installation
- Bundle ID updates
- CocoaPods installation
- Code signing configuration

**Usage**:
```bash
./lib/scripts/ios-workflow/pre-build.sh
```

### 2. **`build.sh`** - Build Process
**Purpose**: Build and archive the iOS app

**Key Features**:
- Flutter project creation (if needed)
- Flutter build
- Xcode archive
- IPA export
- App Store Connect upload (optional)

**Usage**:
```bash
./lib/scripts/ios-workflow/build.sh
```

### 3. **`post-build.sh`** - Post-Build Cleanup
**Purpose**: Cleanup and artifact verification

**Key Features**:
- Temporary file cleanup
- Project backup
- Artifact listing
- IPA verification

**Usage**:
```bash
./lib/scripts/ios-workflow/post-build.sh
```

### 4. **`test_simple_workflow.sh`** - Workflow Test
**Purpose**: Verify workflow readiness

**Key Features**:
- Script existence check
- Executable permissions check
- Tool availability check
- Environment variable check

**Usage**:
```bash
./lib/scripts/ios-workflow/test_simple_workflow.sh
```

## Environment Variables

### Required Variables
```bash
APPLE_TEAM_ID="YOUR_TEAM_ID"
CM_PROVISIONING_PROFILE="BASE64_ENCODED_PROFILE"
CM_CERTIFICATE="BASE64_ENCODED_CERTIFICATE"
CM_CERTIFICATE_PASSWORD="CERTIFICATE_PASSWORD"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
```

### Optional Variables
```bash
APP_STORE_CONNECT_KEY_IDENTIFIER="API_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="ISSUER_ID"
APP_STORE_CONNECT_API_KEY_PATH="API_KEY_URL"
```

## Usage Examples

### Complete Workflow
```bash
# Test workflow readiness
./lib/scripts/ios-workflow/test_simple_workflow.sh

# Run complete workflow
./lib/scripts/ios-workflow/pre-build.sh
./lib/scripts/ios-workflow/build.sh
./lib/scripts/ios-workflow/post-build.sh
```

### Individual Steps
```bash
# Only pre-build setup
./lib/scripts/ios-workflow/pre-build.sh

# Only build process
./lib/scripts/ios-workflow/build.sh

# Only post-build cleanup
./lib/scripts/ios-workflow/post-build.sh
```

## Benefits

### 🚀 **Performance**
- Faster execution (no complex script orchestration)
- Direct command execution
- Minimal overhead

### 🔧 **Reliability**
- Fewer points of failure
- Direct error reporting
- Simple debugging

### 📝 **Maintainability**
- Easy to understand and modify
- Clear purpose for each script
- Minimal dependencies

### 🐛 **Debugging**
- Clear error messages
- Direct command output
- Simple troubleshooting

## Migration from Complex Workflow

### For Existing Users
1. **Backup current scripts** (if needed)
2. **Test new workflow** with `test_simple_workflow.sh`
3. **Update CI/CD** to use new scripts
4. **Remove old complex scripts** (optional)

### For New Users
1. **Set environment variables**
2. **Run test script** to verify setup
3. **Execute workflow** scripts in order

## Troubleshooting

### Common Issues

#### 1. **Flutter Generated Files Missing**
```bash
# Solution: Run flutter pub get
flutter pub get
```

#### 2. **CocoaPods Installation Failed**
```bash
# Solution: Clean and reinstall
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

#### 3. **Code Signing Issues**
```bash
# Solution: Check certificates
security find-identity -v -p codesigning
```

#### 4. **Build Archive Failed**
```bash
# Solution: Check Xcode project
xcodebuild -workspace ios/Runner.xcworkspace -list
```

## Comparison with akash_build.sh

The new workflow follows the same principles as `akash_build.sh`:

### ✅ **Similarities**
- Direct command execution
- Simple error handling
- Clear logging
- Minimal abstraction
- Reliable execution

### 🔄 **Differences**
- Modular design (separate pre-build, build, post-build)
- Better error reporting
- More detailed logging
- Easier to maintain and extend

## Conclusion

The simplified iOS workflow provides:
- **Better reliability** through direct execution
- **Easier maintenance** with clear script purposes
- **Faster execution** with minimal overhead
- **Better debugging** with direct error reporting

This approach eliminates the complexity that was causing issues while maintaining all the necessary functionality for successful iOS builds. 