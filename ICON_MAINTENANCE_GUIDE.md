# Icon Asset Management Guide

## Quick Reference for Icon Updates

### 1. Update App Icon (Launcher Icon)
**File to modify**: `assets/images/orb_icon.png`

**Steps**:
1. Replace the image file with your new app icon (1024x1024 recommended, transparent background OK)
2. Run: `dart run flutter_launcher_icons`
3. Verify icons generated for all platforms

**Platforms updated automatically**:
- ✅ Android: `android/app/src/main/res/mipmap-*/launcher_icon.png`
- ✅ iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- ✅ Web: `web/icons/`
- ✅ Windows: `windows/runner/resources/`
- ✅ macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### 2. Update Notification Icon
**Files to modify**: 
- `android/app/src/main/res/drawable/notification_icon.xml`
- `android/app/src/main/res/drawable-v21/notification_icon.xml`

**Current design**: White checkmark on dark circular background

**If customizing**:
- Keep it simple and monochromatic (Android requirement)
- Use white or light colors only
- Size: 48x48 dp recommended

### 3. Update Notification Color
**File to modify**: `android/app/src/main/res/values/colors.xml`

**Current color**: `#673AB7` (Deep Purple)

**Steps to change**:
1. Update the `notification_icon_color` value
2. Rebuild: `flutter clean && flutter pub get`

### 4. Update Dart Code References
**Files referencing icons**:
- `lib/main.dart` - Notification channel initialization
- `lib/services/notification_helper.dart` - Notification content

**Icon path format**:
- Small icon: `resource://drawable/notification_icon`
- Large icon: `asset://assets/images/orb_icon.png`
- App icon: Automatically managed by flutter_launcher_icons

## Common Tasks

### Add Custom Icon for Specific Task Types
**Goal**: Different notification icons for Assignments, Exams, Projects

**Steps**:
1. Create icons: `assignment_icon.xml`, `exam_icon.xml`, `project_icon.xml`
2. Place in: `android/app/src/main/res/drawable/`
3. Repeat for: `android/app/src/main/res/drawable-v21/`
4. Update `notification_helper.dart`:
   ```dart
   String iconResource = 'resource://drawable/${task.type.toLowerCase()}_icon';
   ```

### Add Badge Count to App Icon
**iOS**: Automatic via `AwesomeNotifications`
```dart
content: NotificationContent(
  badge: 1,  // Shows badge on app icon
  // ... rest of configuration
)
```

**Android**: Requires manufacturer-specific implementation (not standard)

### Update for Rounded Corners (Material Design 3)
Edit notification icons or launcher icon to include rounded corners in the design

### Add Animation to Notifications
**Update `lib/services/notification_helper.dart`**:
```dart
content: NotificationContent(
  // Add animation: can only use system animations
  displayOnForeground: true,
  // Additional visual properties...
)
```

## File Structure Reference

```
assignment_tracker/
├── assets/
│   ├── images/
│   │   └── orb_icon.png  ← Main app icon source
│   └── fonts/
├── android/
│   └── app/src/main/
│       ├── res/
│       │   ├── drawable/
│       │   │   ├── notification_icon.xml  ← ⭐ Notification icon (standard)
│       │   │   └── launch_background.xml
│       │   ├── drawable-v21/
│       │   │   ├── notification_icon.xml  ← ⭐ Notification icon (Android 5.0+)
│       │   │   └── launch_background.xml
│       │   ├── mipmap-*/
│       │   │   └── launcher_icon.png  ← Auto-generated app icon
│       │   ├── values/
│       │   │   ├── colors.xml  ← ⭐ Notification icon color
│       │   │   └── styles.xml
│       │   └── AndroidManifest.xml
│       └── kotlin/
├── ios/
│   ├── Runner/
│   │   ├── Assets.xcassets/AppIcon.appiconset/  ← Auto-generated app icon
│   │   ├── Assets.xcassets/AppIcon.appiconset/Contents.json
│   │   └── Info.plist
│   └── Runner.xcodeproj/
├── lib/
│   ├── main.dart  ← ⭐ Notification channel icon configuration
│   └── services/
│       └── notification_helper.dart  ← ⭐ Notification content icon configuration
├── web/
│   ├── icons/  ← Auto-generated web app icons
│   ├── favicon.ico
│   └── manifest.json
├── windows/
│   └── runner/resources/  ← Auto-generated Windows icons
├── macos/
│   └── Runner/Assets.xcassets/AppIcon.appiconset/  ← Auto-generated macOS icons
└── pubspec.yaml  ← ⭐ Flutter launcher icons configuration
```

## Troubleshooting

### Icons not updating in Android
**Solution**: 
```bash
flutter clean
rm -rf android/app/build
flutter pub get
dart run flutter_launcher_icons
flutter run
```

### Notification icon appears as white blob
**Causes & Solutions**:
1. Icon has colors → Make it monochrome white on transparent
2. Check: `android/app/src/main/res/drawable/notification_icon.xml`
3. Rebuild with `flutter clean`

### App icon not showing on launcher
**Solution for all platforms**:
```bash
flutter clean
dart run flutter_launcher_icons
flutter clean
flutter run --release
```

### Notification color not applying
**Check**:
1. File exists: `android/app/src/main/res/values/colors.xml`
2. Meta-data in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_color"
       android:resource="@color/notification_icon_color" />
   ```

## Testing Icons

### Visual verification checklist
- [ ] App launches with correct icon on home screen
- [ ] Notification appears with checkmark icon
- [ ] Notification color matches deep purple theme
- [ ] Large notification (expanded) shows app icon
- [ ] Status bar icon is visible and crisp
- [ ] All task types show notifications correctly
- [ ] Sound notifications have proper icon
- [ ] Silent notifications have proper icon

### Platform-specific verification
- **Android**: Check Settings → Apps → Assignment Tracker → App icon
- **iOS**: Verify in Xcode → AppIcon.appiconset
- **Web**: Check favicon in browser tab
- **Desktop**: Verify in taskbar (Windows/Linux) and dock (macOS)

## Resources
- [Flutter Launcher Icons Docs](https://pub.dev/packages/flutter_launcher_icons)
- [Android Icon Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design_status_bar.html)
- [iOS App Icon Specifications](https://developer.apple.com/design/resources/)
- [Material Design Icons](https://fonts.google.com/icons)
