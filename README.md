# FocusLock for iPhone

FocusLock is an iPhone app project that combines:

- a Pomodoro timer
- a daily study target
- a history screen for daily, weekly, and monthly progress
- Screen Time shielding that keeps selected apps blocked until the day's target is finished

## What is in this repo

- `FocusLock.xcodeproj`: the iPhone app project
- `FocusLock/`: the SwiftUI app target
- `Extensions/ActivityMonitor/`: the Screen Time monitor extension for daily reset handling
- `FocusLockShared/`: shared app group storage and shielding helpers
- `Sources/FocusLockCore/`: the shared focus analytics logic
- `Tests/FocusLockCoreTests/`: unit tests for the progress calculations

## Open and run on iPhone

1. Open `FocusLock.xcodeproj` in Xcode on a Mac with full Xcode installed.
2. In the project settings, select your Apple Developer team for both targets.
3. The project is preconfigured with:
   - `com.georgesiriban.FocusLock`
   - `com.georgesiriban.FocusLock.ActivityMonitor`
4. Keep the app group identifier aligned across the app and extension:
   - `group.com.georgesiriban.FocusLock`
5. Run the `FocusLock` target on your connected iPhone.
6. Inside the app, grant Screen Time permission and pick the apps or categories you want blocked.

## Important Apple requirements

This project is ready as source, but Apple still requires local signing and entitlements setup in Xcode before it can be installed on a real iPhone. That part cannot be finished from this command-line-only environment because full Xcode is not installed here.

The blocking implementation is based on Apple's Screen Time frameworks:

- `FamilyControls`
- `ManagedSettings`
- `DeviceActivity`

Official references:

- [FamilyControls](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings](https://developer.apple.com/documentation/managedsettings)
- [DeviceActivity](https://developer.apple.com/documentation/deviceactivity)
- [Configuring Family Controls](https://developer.apple.com/documentation/xcode/configuring-family-controls)
