# Premium & StoreKit

## What's behind the paywall

Features are **hidden** when unavailable:

- **Sounds**: rain, fan, fireplace (3 additional sounds)
- **Nightlight**: keep screen on with a soft glow while falling asleep
- **Themes**: Dusk, Midnight, Green

Access is granted if the user has purchased premium **or** is in an active trial.

## Purchase model

One-time non-consumable purchase for $3. Implemented with StoreKit 2 (async/await, no third-party SDK).
I followed [this guide](https://www.revenuecat.com/blog/engineering/ios-in-app-subscription-tutorial-with-storekit-2-and-swift/)
Product ID: `com.dalbers.WhiteNoise.premium` configured in `Store.storekit`

## Architecture

Two managers own all logic

* `EntitlementsManager` - Source of truth for what the user has access to. It takes into account trial status from SettingsSource and entitlements (purchases) from StoreKit
* `PurchaseManager` - handles the purchase flow. Mutates `EntitlementsManager.hasPremium` on success.

## Trial system

- User taps "Try free" → `EntitlementsManager.startTrial()` writes the current date to UserDefaults
- Trial lasts 30 days from that date
- `isInTrial` and `hasPremiumAccess` are computed on every access, so expiry is automatic
- After expiry: banner shows "Trial ended" subtitle and "Buy for $3" button
