# Simple iOS Workflow Guide

## Overview

The `simple_ios_build.sh` script is a comprehensive, single-file iOS build workflow that combines the best practices from `akash_build.sh` with current environment variables and Dart-specific requirements.

## 🚀 Key Features

### Single Script Solution
- **Complete workflow** in one file
- **No complex orchestration** between multiple scripts
- **Self-contained** with all necessary steps
- **Easy to maintain** and debug

### Environment Variable Compatibility
- Uses **current environment variables** (not AKASH-specific ones)
- **Automatic extraction** from provisioning profiles
- **Fallback mechanisms** for missing variables
- **Clear validation** and error messages

### Dart/Flutter Integration
- **Missing file detection** and restoration
- **Preprocessor directive fixes**
- **Flutter project validation**
- **Dependency management**

## 📋 Script Structure

The script is organized into 12 phases:

### Phase 1: Pre-build Cleanup and Setup
- Flutter clean
- Derived data cleanup
- Keychain initialization

### Phase 2: Environment Variables Setup
- Variable validation
- Provisioning profile extraction
- Default value assignment

### Phase 3: Provisioning Profile and Certificate Setup
- Profile installation
- Certificate management
- Signing identity validation

### Phase 4: Dart/Flutter Setup
- Missing file fixes
- Preprocessor directive fixes
- Flutter project validation

### Phase 5: Bundle Identifier Update
- Project.pbxproj updates
- Info.plist updates
- Entitlements updates

### Phase 6: CocoaPods Setup
- Podfile.lock management
- Pod installation
- Dependency resolution

### Phase 7: Xcode Configuration
- Release.xcconfig updates
- Code signing setup
- Project configuration

### Phase 8: Flutter Build
- Release build
- No codesign option
- Build logging

### Phase 9: Xcode Archive
- Workspace archive
- Development team setup
- Archive logging

### Phase 10: IPA Export
- ExportOptions.plist creation
- Archive export
- IPA generation

### Phase 11: IPA Verification and Upload
- IPA location detection
- App Store Connect upload
- API key management

### Phase 12: Cleanup and Finalization
- Temporary file cleanup
- Project backup
- Artifact listing

## 🔧 Environment Variables

### Required Variables
```bash
UUID                    # Provisioning profile UUID
BUNDLE_ID              # App bundle identifier
APPLE_TEAM_ID          # Apple Developer Team ID
```

### Optional Variables (with defaults)
```bash
CM_DISTRIBUTION_TYPE="Apple Distribution"
CODE_SIGNING_STYLE="manual"
VERSION_NAME="1.0.0"
VERSION_CODE="1"
```

### Certificate Variables
```bash
CM_PROVISIONING_PROFILE    # Base64 encoded provisioning profile
CM_CERTIFICATE            # Base64 encoded certificate
CM_CERTIFICATE_PASSWORD   # Certificate password
```

### App Store Connect Variables
```bash
APP_STORE_CONNECT_KEY_IDENTIFIER    # API key identifier
APP_STORE_CONNECT_ISSUER_ID         # API issuer ID
APP_STORE_CONNECT_API_KEY_PATH      # API key download URL
```

## 🚀 Usage

### Basic Usage
```bash
./lib/scripts/ios-workflow/simple_ios_build.sh
```

### With Environment Variables
```bash
export UUID="your-uuid"
export BUNDLE_ID="com.yourcompany.yourapp"
export APPLE_TEAM_ID="your-team-id"
./lib/scripts/ios-workflow/simple_ios_build.sh
```

### In CI/CD Pipeline
```yaml
- name: Build iOS App
  script:
    - chmod +x lib/scripts/ios-workflow/simple_ios_build.sh
    - ./lib/scripts/ios-workflow/simple_ios_build.sh
```

## 🔍 Error Handling

### Automatic Recovery
- **Missing files**: Automatically restored from backups
- **Preprocessor issues**: Automatically fixed
- **Environment variables**: Extracted from provisioning profiles
- **CocoaPods issues**: Automatic Podfile.lock management

### Clear Error Messages
- **Specific error descriptions**
- **Actionable solutions**
- **Phase-specific logging**
- **Exit codes for CI/CD**

### Validation Steps
- ✅ Environment variables validation
- ✅ Signing identity verification
- ✅ Flutter project validation
- ✅ IPA file verification

## 📊 Logging and Monitoring

### Phase-based Logging
Each phase provides:
- **Start/end indicators**
- **Progress updates**
- **Error details**
- **Success confirmations**

### Build Artifacts
- **flutter_build.log**: Flutter build output
- **xcodebuild_archive.log**: Xcode archive output
- **project_backup.zip**: Project backup
- **build/ios/output/**: IPA files
- **build/ios/archive/**: Xcode archives

## 🔧 Troubleshooting

### Common Issues

#### 1. Environment Variables Missing
```bash
❌ UUID is not set and could not be extracted from provisioning profile
```
**Solution**: Set UUID environment variable or ensure provisioning profile is available

#### 2. Signing Identity Issues
```bash
❌ No valid Apple Distribution signing identities found in keychain
```
**Solution**: Ensure certificate is properly installed and CM_CERTIFICATE is set

#### 3. Flutter Project Issues
```bash
❌ Runner.xcworkspace not found
```
**Solution**: Script automatically creates iOS project if missing

#### 4. CocoaPods Issues
```bash
❌ pod install failed
```
**Solution**: Script automatically manages Podfile.lock and retries installation

### Debug Mode
To enable verbose output, modify the script:
```bash
# Add this line after set -euo pipefail
set -x  # Enable verbose shell output
```

## 🎯 Benefits Over Complex Workflow

### Simplicity
- **Single file** instead of multiple scripts
- **Linear execution** instead of complex orchestration
- **Easy debugging** with phase-based logging
- **Self-contained** with all dependencies

### Reliability
- **Automatic error recovery**
- **Comprehensive validation**
- **Clear error messages**
- **Robust fallback mechanisms**

### Maintainability
- **Clear phase structure**
- **Well-documented sections**
- **Consistent logging**
- **Easy to modify**

## 🔄 Migration from Complex Workflow

### Replace Multiple Scripts
Instead of:
```bash
./lib/scripts/ios-workflow/pre-build.sh
./lib/scripts/ios-workflow/build.sh
./lib/scripts/ios-workflow/post-build.sh
```

Use:
```bash
./lib/scripts/ios-workflow/simple_ios_build.sh
```

### Environment Variables
The script automatically handles:
- **Variable extraction** from provisioning profiles
- **Default value assignment**
- **Validation and error handling**
- **Export for other processes**

## 📈 Performance Optimizations

### Cleanup Strategies
- **Selective cleanup** based on phase
- **Temporary file management**
- **Derived data cleanup**
- **Build artifact organization**

### Caching
- **Podfile.lock backup** and restoration
- **Project backup** creation
- **Log preservation** for debugging

## 🎉 Success Indicators

The script is successful when you see:
```
🎉 Simple iOS Build Workflow completed successfully!
📱 IPA Location: /path/to/your/app.ipa
📦 Archive Location: build/ios/archive/Runner.xcarchive
📋 Build Logs: flutter_build.log, xcodebuild_archive.log
```

## 🔮 Future Enhancements

### Planned Features
- **Parallel processing** for independent phases
- **Incremental builds** for faster development
- **Custom phase hooks** for extensibility
- **Advanced error recovery** mechanisms

### Integration Options
- **CI/CD platform** specific optimizations
- **Cloud build** service compatibility
- **Local development** workflow integration
- **Team collaboration** features 