# Notification Sound Selection — Design Spec

## Overview

Add a user-selectable notification sound to the Drink Water Reminder app. Users can pick from macOS built-in system sounds in Settings. The selected sound plays when the countdown timer reaches zero and the notification fires.

## Changes

### DataManager

- Add `@Published var notificationSound: String` backed by `UserDefaults` key `"notificationSound"`, default `"Default"`.
- Add a static list of available sounds:
  ```
  ["Default", "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
  ```

### TimerManager

- Modify `fireNotificationIfNeeded()` to accept a `soundName: String` parameter.
- If `soundName == "Default"`, use `UNNotificationSound.default`.
- Otherwise, use `UNNotificationSound(named: UNNotificationSoundName("\(soundName).aiff"))`.
- The caller (the timer tick sink) passes `dataManager.notificationSound`. This requires TimerManager to have a reference to the sound name — passed via a new method or stored property.

**Simplest approach:** Add a `var selectedSound: String = "Default"` property to TimerManager. The app entry point or MainPopoverView keeps it in sync with `dataManager.notificationSound`. TimerManager uses `selectedSound` when firing notifications.

### SettingsView

- Add a `Picker` labeled "Notification Sound" with `.menu` style, listing all available sounds from `DataManager.availableSounds`.
- Bound to `$dataManager.notificationSound`.
- On change, play a preview using `NSSound(named: NSSound.Name(soundName))?.play()`.
- Placed between "Daily Goal" and "Launch at Login" sections.

## Files Modified

- `DrinkWaterReminder/Managers/DataManager.swift` — add `notificationSound` property and `availableSounds` constant
- `DrinkWaterReminder/Managers/TimerManager.swift` — use selected sound in notification content
- `DrinkWaterReminder/Views/SettingsView.swift` — add sound picker with preview
- `DrinkWaterReminder/Views/MainPopoverView.swift` — sync sound setting to TimerManager

## No New Files

No new models, views, or assets required.
