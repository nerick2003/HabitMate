# Quick Fix - Can't Run the Code

## The Problem
All the red errors you're seeing are because **Flutter packages aren't installed**. The code is correct, but you need to install dependencies first.

## Solution

### Option 1: If Flutter is Installed (but not in PATH)

1. **Find where Flutter is installed** (common locations):
   - `C:\src\flutter`
   - `C:\flutter`
   - `C:\Users\YourName\flutter`

2. **Open PowerShell/Command Prompt in the project folder:**
   ```powershell
   cd C:\Users\neric\Desktop\HabitMate
   ```

3. **Run Flutter directly with full path:**
   ```powershell
   C:\src\flutter\bin\flutter pub get
   ```
   (Replace `C:\src\flutter` with your actual Flutter path)

### Option 2: If Flutter is NOT Installed

1. **Install Flutter:**
   - Download: https://flutter.dev/docs/get-started/install/windows
   - Extract to `C:\src\flutter` (or any location)
   - Add to PATH:
     - Open System Properties → Environment Variables
     - Edit "Path" variable
     - Add: `C:\src\flutter\bin`
   - **Restart your computer or IDE**

2. **Verify installation:**
   ```powershell
   flutter --version
   ```

3. **Install dependencies:**
   ```powershell
   cd C:\Users\neric\Desktop\HabitMate
   flutter pub get
   ```

### Option 3: Using Android Studio / VS Code

**If using Android Studio:**
1. Open the project
2. Click "Pub get" button at the top (or Tools → Flutter → Pub get)
3. Wait for packages to install
4. Click Run button

**If using VS Code:**
1. Open the project folder
2. Press `Ctrl+Shift+P`
3. Type "Flutter: Get Packages"
4. Press Enter
5. Wait for installation
6. Press `F5` to run

## After Installing Dependencies

Once `flutter pub get` completes successfully:

1. **The red errors should disappear** (may need to restart IDE)
2. **You can run the app:**
   ```powershell
   flutter run
   ```

## Still Having Issues?

**Check if Flutter is accessible:**
- Open a NEW terminal/PowerShell window
- Type: `flutter --version`
- If it says "not recognized", Flutter is not in PATH

**Common Flutter installation paths to check:**
- `C:\src\flutter\bin\flutter.exe`
- `C:\flutter\bin\flutter.exe`
- `C:\Users\YourName\AppData\Local\flutter\bin\flutter.exe`

**If you find Flutter.exe, you can:**
1. Use the full path to run commands
2. Or add that folder to your PATH

---

**Need help finding Flutter?** Search your computer for `flutter.exe` - that will tell you where it's installed!

