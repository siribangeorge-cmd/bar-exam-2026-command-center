# Install on iPhone

## Before you run

- Install full Xcode on your Mac.
- Sign in to Xcode with your Apple ID.
- Connect your iPhone or use wireless debugging.

## In Xcode

1. Open `FocusLock.xcodeproj`.
2. Select the `FocusLock` project in the navigator.
3. Set your team for:
   - `FocusLock`
   - `FocusLockActivityMonitor`
4. Confirm these bundle identifiers are accepted by your Apple account:
   - `com.georgesiriban.FocusLock`
   - `com.georgesiriban.FocusLock.ActivityMonitor`
5. Confirm the app group string matches in:
   - `FocusLock/FocusLock.entitlements`
   - `Extensions/ActivityMonitor/ActivityMonitor.entitlements`
   - `group.com.georgesiriban.FocusLock`
6. Build and run the `FocusLock` app target on your iPhone.

## First launch

1. Tap `Request Screen Time Access`.
2. Tap `Choose Apps and Categories`.
3. Select Instagram, YouTube, Facebook, or any apps you want blocked.
4. Set your daily target hours.
5. Start a focus session.

## Current product scope

- Pomodoro timer
- Daily target progress
- Daily history list
- Weekly and monthly totals
- Selected apps stay shielded until the target is reached
- Daily boundary monitor re-applies shielding for a new day
