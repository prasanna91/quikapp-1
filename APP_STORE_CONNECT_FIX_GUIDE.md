# 🛡️ App Store Connect Issues Fix Guide

## 📋 **Issues to Fix**

### **Issue 1: ITMS-90685 - CFBundleIdentifier Collision**
```
ITMS-90685: CFBundleIdentifier Collision - There is more than one bundle with the CFBundleIdentifier value 'com.garbcode.garbcodeapp' under the iOS application 'Runner.app'.
```

### **Issue 2: ITMS-90183 - Invalid Bundle OS Type**
```
ITMS-90183: Invalid Bundle OS Type code - The CFBundlePackageType value in the com.garbcode.garbcodeapp app bundle's Info.plist file must be one of the following Bundle OS Type codes: [APPL].
```

---

## 🔧 **Solution Implementation**

### **1. Automatic Fix Script**
I've created a comprehensive fix script that addresses both issues:

**File**: `lib/scripts/ios/fix_app_store_connect_issues.sh`

**Features**:
- ✅ Fixes CFBundleIdentifier collisions in frameworks
- ✅ Fixes CFBundleIdentifier collisions in plugins
- ✅ Fixes CFBundleIdentifier collisions in bundles
- ✅ Sets CFBundlePackageType to "APPL"
- ✅ Validates app bundle structure
- ✅ Creates detailed fix report

### **2. Workflow Integration**
The iOS workflow now includes an automatic App Store Connect fix step:

**File**: `lib/scripts/ios-workflow/app-store-connect-fix.sh`

**Integration**: Added to the iOS workflow in `codemagic.yaml`

---

## 🚀 **How to Use**

### **Option 1: Automatic Fix (Recommended)**
The fix is now integrated into the iOS workflow and will run automatically after the build.

1. **Trigger the iOS workflow** in Codemagic
2. **Wait for the build** to complete
3. **The App Store Connect fix** will run automatically
4. **Upload the fixed IPA** to App Store Connect

### **Option 2: Manual Fix**
If you need to fix an existing IPA manually:

```bash
# Make the script executable
chmod +x lib/scripts/ios/fix_app_store_connect_issues.sh

# Run the fix
./lib/scripts/ios/fix_app_store_connect_issues.sh "com.garbcode.garbcodeapp" "/path/to/Runner.app"
```

---

## 🔍 **What the Fix Does**

### **CFBundleIdentifier Collision Fix (ITMS-90685)**

**Problem**: Multiple bundles have the same bundle ID `com.garbcode.garbcodeapp`

**Solution**: 
1. **Scans all frameworks** in the app bundle
2. **Identifies collisions** with the main app bundle ID
3. **Creates unique bundle IDs** for frameworks:
   - `com.garbcode.garbcodeapp.framework.{framework_name}`
4. **Scans all plugins/extensions** and fixes collisions:
   - `com.garbcode.garbcodeapp.plugin.{plugin_name}`
5. **Scans all bundles** and fixes collisions:
   - `com.garbcode.garbcodeapp.bundle.{bundle_name}`

**Example**:
```
Before:
- Main App: com.garbcode.garbcodeapp
- Framework: com.garbcode.garbcodeapp ❌ (collision)

After:
- Main App: com.garbcode.garbcodeapp
- Framework: com.garbcode.garbcodeapp.framework.Flutter ✅ (unique)
```

### **CFBundlePackageType Fix (ITMS-90183)**

**Problem**: CFBundlePackageType is not set to "APPL"

**Solution**:
1. **Checks current CFBundlePackageType** in Info.plist
2. **Sets CFBundlePackageType to "APPL"** if not already set
3. **Verifies the change** was applied correctly

**Example**:
```xml
<!-- Before -->
<key>CFBundlePackageType</key>
<string>FMWK</string>

<!-- After -->
<key>CFBundlePackageType</key>
<string>APPL</string>
```

---

## 📊 **Bundle ID Distribution**

After the fix, your bundle IDs will be distributed as follows:

| Component | Bundle ID Pattern | Example |
|-----------|-------------------|---------|
| **Main App** | `com.garbcode.garbcodeapp` | `com.garbcode.garbcodeapp` |
| **Frameworks** | `com.garbcode.garbcodeapp.framework.{name}` | `com.garbcode.garbcodeapp.framework.Flutter` |
| **Plugins** | `com.garbcode.garbcodeapp.plugin.{name}` | `com.garbcode.garbcodeapp.plugin.Firebase` |
| **Bundles** | `com.garbcode.garbcodeapp.bundle.{name}` | `com.garbcode.garbcodeapp.bundle.Resources` |

---

## 📋 **Validation Steps**

### **1. Check Bundle ID Distribution**
```bash
# Extract IPA and check bundle IDs
unzip -q your_app.ipa
find Payload -name "Info.plist" -exec plutil -extract CFBundleIdentifier raw {} \;
```

### **2. Verify CFBundlePackageType**
```bash
# Check main app Info.plist
plutil -extract CFBundlePackageType raw Payload/Runner.app/Info.plist
# Should return: APPL
```

### **3. Check for Collisions**
```bash
# List all bundle IDs
find Payload -name "Info.plist" -exec sh -c 'echo "=== {} ==="; plutil -extract CFBundleIdentifier raw {}' \;
```

---

## 📈 **Expected Results**

### **Before Fix**
```
❌ ITMS-90685: CFBundleIdentifier Collision
❌ ITMS-90183: Invalid Bundle OS Type
❌ App Store Connect upload fails
```

### **After Fix**
```
✅ No CFBundleIdentifier collisions
✅ CFBundlePackageType = "APPL"
✅ App Store Connect upload succeeds
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

1. **Script Not Found**
   ```bash
   # Make sure the script is executable
   chmod +x lib/scripts/ios/fix_app_store_connect_issues.sh
   ```

2. **IPA Extraction Failed**
   ```bash
   # Check if IPA is valid
   file your_app.ipa
   # Should show: ZIP archive data
   ```

3. **Permission Denied**
   ```bash
   # Check file permissions
   ls -la lib/scripts/ios/fix_app_store_connect_issues.sh
   ```

### **Debugging**

1. **Check the fix report**:
   ```
   output/ios/APP_STORE_CONNECT_FIX_REPORT.txt
   ```

2. **Verify IPA structure**:
   ```bash
   unzip -l your_app.ipa | grep -E "(Info\.plist|\.framework|\.appex)"
   ```

3. **Test with a small IPA first**:
   ```bash
   # Create a test IPA and verify the fix works
   ```

---

## 🚀 **Upload to App Store Connect**

### **Step 1: Build with Fix**
1. Trigger the iOS workflow in Codemagic
2. Wait for the build to complete
3. The App Store Connect fix will run automatically

### **Step 2: Download Fixed IPA**
1. Go to the build artifacts
2. Download the fixed IPA from `output/ios/`

### **Step 3: Upload to App Store Connect**
1. Open App Store Connect
2. Go to your app
3. Click "TestFlight" or "App Store"
4. Upload the fixed IPA
5. The issues should be resolved

---

## ✅ **Success Criteria**

After applying the fix, you should see:

1. **No ITMS-90685 errors** in App Store Connect
2. **No ITMS-90183 errors** in App Store Connect
3. **Successful upload** to App Store Connect
4. **App appears** in TestFlight or App Store

---

## 📞 **Support**

If you encounter any issues:

1. **Check the fix report**: `output/ios/APP_STORE_CONNECT_FIX_REPORT.txt`
2. **Review build logs** for any error messages
3. **Verify IPA structure** manually if needed
4. **Test with a different bundle ID** if problems persist

The fix is designed to be **safe and reliable**, but always test thoroughly before uploading to production. 