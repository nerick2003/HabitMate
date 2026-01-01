# Troubleshooting Guide - Why Can't I Run the Code?

## Common Issues and Solutions

### Issue 1: Flutter Not Installed or Not in PATH

**Symptoms:**
- Error: `'flutter' is not recognized as a command`
- IDE shows "Flutter SDK not found"

**Solution:**
1. **Install Flutter:**
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Extract to a location like `C:\src\flutter`
   - Add Flutter to your PATH:
     - Open System Properties → Environment Variables
     - Add `C:\src\flutter\bin` to your PATH
   - Restart your terminal/IDE

2. **Verify Installation:**
   ```bash
   flutter doctor
   ```

### Issue 2: Missing Android/iOS Platform Folders

**Symptoms:**
- Error: "No Android SDK found" or "No iOS project found"
- Missing `android/` or `ios/` folders

**Solution:**
1. **If Flutter is installed**, run in the project directory:
   ```bash
   flutter create . --platforms=android,ios
   ```
   This will create the missing platform folders without overwriting your `lib/` folder.

2. **If using Android Studio/VS Code:**
   - Open the project in your IDE
   - The IDE should prompt you to create platform folders
   - Or use: Tools → Flutter → Create Project (in Android Studio)

### Issue 3: Dependencies Not Installed

**Symptoms:**
- Import errors in IDE
- "Package not found" errors

**Solution:**
```bash
cd C:\Users\neric\Desktop\HabitMate
flutter pub get
```

### Issue 4: No Device/Emulator Available

**Symptoms:**
- Error: "No devices found"
- Can't select a device to run on

**Solution:**
1. **For Android:**
   - Open Android Studio
   - Tools → Device Manager
   - Create a new virtual device (AVD)
   - Or connect a physical Android device via USB with USB debugging enabled

2. **For iOS (macOS only):**
   - Open Xcode
   - Window → Devices and Simulators
   - Create a new simulator or use an existing one

3. **Check available devices:**
   ```bash
   flutter devices
   ```

### Issue 5: Compilation Errors

**Symptoms:**
- Red squiggly lines in IDE
- Build fails with specific error messages

**Common fixes:**
1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Dart/Flutter version:**
   ```bash
   flutter --version
   ```
   Should be Flutter 3.0.0+ and Dart 3.0.0+

3. **Update dependencies:**
   ```bash
   flutter pub upgrade
   ```

### Issue 6: Android SDK Issues

**Symptoms:**
- "Android SDK not found"
- Build errors related to Android

**Solution:**
1. Install Android Studio
2. Open Android Studio → SDK Manager
3. Install:
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - At least one Android SDK Platform (API 21+)
4. Set ANDROID_HOME environment variable:
   - Usually: `C:\Users\YourName\AppData\Local\Android\Sdk`

### Issue 7: Code-Specific Issues

**If you see import errors:**
- Make sure all files in `lib/` are present
- Check that `pubspec.yaml` has all dependencies
- Run `flutter pub get`

**If notifications don't work:**
- This is expected if you haven't set up Android permissions yet
- The app will still run, just notifications won't work
- See SETUP.md for Android permission setup

## Step-by-Step Setup (First Time)

1. **Install Flutter:**
   - Download: https://flutter.dev/docs/get-started/install/windows
   - Extract and add to PATH
   - Run `flutter doctor` and fix any issues

2. **Install Android Studio:**
   - Download: https://developer.android.com/studio
   - Install Android SDK through SDK Manager

3. **Create Platform Folders:**
   ```bash
   cd C:\Users\neric\Desktop\HabitMate
   flutter create . --platforms=android,ios
   ```

4. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

5. **Create/Start Emulator:**
   - Open Android Studio → Device Manager
   - Create a new AVD
   - Start the emulator

6. **Run the App:**
   ```bash
   flutter run
   ```
   Or click the Run button in your IDE

## Quick Diagnostic Commands

Run these to diagnose issues:

```bash
# Check Flutter installation
flutter doctor -v

# Check available devices
flutter devices

# Check project setup
flutter analyze

# Get dependencies
flutter pub get

# Clean build
flutter clean
```

## Still Having Issues?

1. **Check the exact error message** - it usually tells you what's wrong
2. **Check Flutter Doctor output** - it shows what's missing
3. **Make sure you're in the project directory** when running commands
4. **Restart your IDE** after installing Flutter
5. **Check that your PATH includes Flutter/bin**

## Common Error Messages

| Error | Solution |
|-------|----------|
| "Flutter SDK not found" | Install Flutter and add to PATH |
| "No devices found" | Create/start an emulator or connect device |
| "Package not found" | Run `flutter pub get` |
| "Android SDK not found" | Install Android Studio and SDK |
| "Gradle build failed" | Check Android SDK installation |
| "CocoaPods not found" (iOS) | Run `pod install` in ios/ folder |

---

**Need more help?** Check the official Flutter docs: https://flutter.dev/docs

