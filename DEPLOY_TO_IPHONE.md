# 📱 Deploy to Your iPhone - Step by Step

## ✅ Code Issues - FIXED!
All compilation errors have been resolved. Your app should now build successfully.

## 📝 Step 1: Change Bundle Identifier (REQUIRED)

### Option A: In Xcode (Recommended)
1. **Open your project in Xcode**
2. **Click the blue project icon** at the top of the file navigator (left sidebar)
3. **Select your target** under "TARGETS" (probably called "HallPass" or "TeacherLink")
4. **Click "Signing & Capabilities"** tab
5. **Find "Bundle Identifier"** field
6. **Change from**: `com.hallpass.app`
7. **Change to**: `com.yourname.hallpass` (use your actual name, all lowercase, no spaces)
   
   Examples:
   - `com.johnsmith.hallpass`
   - `com.sarahj.hallpass`
   - `com.myschool.hallpass`

### Option B: Using Terminal (Advanced)
If you want to automate this, run these commands in Terminal from your project directory:

```bash
# Replace YOUR_NAME with your actual name (lowercase, no spaces)
YOUR_NAME="johnsmith"  # Change this!

# Find and update the bundle identifier in all xcconfig files
find . -name "*.xcconfig" -exec sed -i '' "s/com.hallpass.app/com.$YOUR_NAME.hallpass/g" {} \;

# Update Info.plist files
find . -name "Info.plist" -exec /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.$YOUR_NAME.hallpass" {} \; 2>/dev/null
```

## 📱 Step 2: Prepare Your iPhone

1. **Connect your iPhone** to your Mac with a cable
2. **Unlock your iPhone**
3. **Trust this computer** (if prompted on iPhone)
4. **On iPhone**: Go to Settings → General → VPN & Device Management
   - You'll configure this after the first build

## 🔐 Step 3: Code Signing in Xcode

1. **Still in "Signing & Capabilities" tab**
2. **Check "Automatically manage signing"**
3. **Select your Team**:
   - If you have an Apple Developer account: Select your team
   - If not: Select your personal Apple ID (you'll see "Personal Team")
4. Xcode will automatically create a provisioning profile

### If you don't see your Apple ID:
1. Go to **Xcode → Settings** (or **Preferences** in older Xcode)
2. Click **Accounts** tab
3. Click **+** to add your Apple ID
4. Sign in with your Apple ID

## 🏗️ Step 4: Build and Run

1. **At the top of Xcode**, near the play button, click the device selector
2. **Select your iPhone** from the list (not a simulator)
3. **Click the Play button** (▶️) or press **⌘R**
4. Wait for the build to complete

### First time deployment:
- Xcode will install the app on your iPhone
- You'll see the app icon appear on your home screen

## ⚠️ Step 5: Trust Developer Certificate (First Time Only)

After the first install, you need to trust your developer certificate:

1. **On your iPhone**: Settings → General → VPN & Device Management
2. Find your Apple ID or developer name
3. Tap it and select **Trust**
4. Confirm

Now you can launch the app!

## 🎯 Quick Reference

### If Build Fails:
```
1. Clean Build Folder: ⇧⌘K (Shift+Cmd+K)
2. Close Xcode
3. Delete Derived Data:
   Xcode → Settings → Locations → Click arrow next to Derived Data
   Delete your project's folder
4. Reopen Xcode
5. Try again
```

### If "App Not Installed" Error:
- Make sure you changed the bundle identifier
- Make sure you selected a valid team in Signing & Capabilities
- Try cleaning and rebuilding

### If Certificate Errors:
- Go to Xcode → Settings → Accounts
- Select your Apple ID
- Click "Download Manual Profiles"
- Try again

## 🆓 Free Apple Developer Account Limitations

If you're using a free Apple ID (not paid developer account):
- ✅ You can deploy to your own device
- ✅ App works for 7 days before needing to be reinstalled
- ✅ Up to 3 devices at a time
- ❌ No TestFlight
- ❌ No App Store distribution

To keep using the app after 7 days:
- Simply rebuild and reinstall from Xcode
- Or sign up for Apple Developer Program ($99/year)

## 📋 Checklist

- [ ] Bundle identifier changed to something unique
- [ ] iPhone connected and trusted
- [ ] Apple ID added to Xcode
- [ ] Team selected in Signing & Capabilities
- [ ] iPhone selected as destination (not simulator)
- [ ] Build successful (⌘R)
- [ ] Developer certificate trusted on iPhone
- [ ] App launches on iPhone

## 🎉 Success!

Once complete, your HallPass app will be running on your iPhone!

## 🐛 Common Issues

### "Signing for 'HallPass' requires a development team"
**Fix**: Select a team in Signing & Capabilities (see Step 3)

### "Unable to install"
**Fix**: 
1. Delete the app from your iPhone if it exists
2. Restart Xcode
3. Clean build folder (⇧⌘K)
4. Try again

### "Could not launch"
**Fix**: Trust the developer certificate on your iPhone (see Step 5)

### Multiple targets showing errors
**Fix**: Make sure to update the bundle identifier for ALL targets in your project

---

**Need more help?** Let me know what error message you're seeing!
