# HabitMate 📱

A beautiful and intuitive habit & routine tracker app built with Flutter for Android and iOS. Help yourself build better habits, one day at a time!

## ✨ Features

- **Habit Creation**: Add custom habits with icons, colors, and descriptions
- **Daily Checklist**: Track your daily habits with a simple check/uncheck interface
- **Streak Tracking**: See your current streak and stay motivated
- **Progress Analytics**: View your success rate and weekly progress charts
- **Smart Reminders**: Set multiple reminder times for each habit
- **Beautiful UI**: Modern, clean design with Material 3
- **Local Storage**: All data stored locally on your device

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for running on devices)
- An Android device/emulator or iOS simulator

### Installation

1. **Clone or navigate to the project directory:**
   ```bash
   cd HabitMate
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Platform Setup

### Android

The app should work out of the box on Android. For notifications to work properly on Android 13+, make sure your `android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS

For iOS, you may need to configure notification permissions in `ios/Runner/Info.plist`. The app will request permissions when needed.

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── habit_model.dart      # Habit and HabitCompletion models
├── screens/
│   ├── splash_screen.dart    # Splash/loading screen
│   ├── home_screen.dart      # Main dashboard
│   ├── add_habit_screen.dart # Add/Edit habit screen
│   └── habit_details_screen.dart # Habit details with analytics
├── services/
│   ├── db_service.dart       # SQLite database service
│   └── notification_service.dart # Local notifications
└── widgets/
    └── habit_tile.dart       # Reusable habit list item widget
```

## 🛠️ Technologies Used

- **Flutter** - UI framework
- **Dart** - Programming language
- **sqflite** - Local SQLite database
- **flutter_local_notifications** - Local push notifications
- **fl_chart** - Beautiful charts for analytics
- **intl** - Date/time formatting

## 📖 Usage

1. **Add a Habit**: Tap the "+" button on the home screen
2. **Complete Habits**: Check off habits as you complete them each day
3. **View Progress**: Tap on any habit to see detailed stats and charts
4. **Set Reminders**: Add reminder times when creating/editing a habit
5. **Track Streaks**: Watch your streak grow as you maintain consistency

## 🎨 Customization

- Choose from 10 different icons for your habits
- Select from 8 color themes
- Set daily or weekly frequency
- Add multiple reminder times per habit

## 📊 Features in Detail

### Streak System
Tracks consecutive days of completion. Your streak resets if you miss a day.

### Success Rate
Calculates your completion percentage over the last 30 days.

### Weekly Charts
Visual bar chart showing your completion status for the last 7 days.

## 🔮 Future Enhancements

- Dark mode support
- Cloud sync (Firebase)
- Habit categories/tags
- Export data
- Social sharing
- Widget support

## 📝 License

This project is open source and available for personal use.

## 🤝 Contributing

Feel free to fork, modify, and use this project for your own purposes!

---

**Built with ❤️ using Flutter**

