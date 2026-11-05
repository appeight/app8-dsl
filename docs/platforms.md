# Platforms

The App8 DSL renders natively on iOS (UIKit, `app8-ios-sdk`) and Android
(Jetpack Compose, `app8-android-sdk`). One JSON app runs on both. This page
lists what differs between the platforms and how an app says so.

## Principle: brand content identical, system chrome native

Everything an app designs itself renders the same on both platforms: views,
labels, images, shapes, materials, colors, fonts, corner radii, layout and
animations. Parts that belong to the operating system follow that system's
conventions, so the app feels at home on each:

| Concern | iOS | Android |
|---|---|---|
| Navigation bar | `UINavigationBar`, large titles, chevron back button | Material 3 top app bar, arrow back button |
| Back navigation | Edge swipe | System back gesture with predictive back preview |
| Tab bar (`tabBarScreen`) | `UITabBar` (floating glass capsule on iOS 26) | Material 3 `NavigationBar` |
| Press feedback (`button`) | Highlight and dim | Ripple |
| Scroll edges | Rubber band and bounce | Stretch overscroll |
| Scroll indicators | Thin overlay bars that fade | None by default |
| `system` font | SF Pro | Roboto (Google Sans on Pixel when available) |
| `corner.curve: continuous` | Continuous (squircle) corners | Continuous corners, drawn as a path |
| Sheets (`presentation: sheet`) | `UISheetPresentationController` | Material 3 modal bottom sheet |
| Alerts (`showAlert`) | `UIAlertController` | Material 3 `AlertDialog` |
| Haptics (`haptic`) | `UIFeedbackGenerator` | `HapticFeedbackConstants` |
| `openURL` in sheet | `SFSafariViewController` | Custom Tabs |
| Safe area | Status bar, Dynamic Island, home indicator | Status bar, display cutout, gesture or 3-button navigation bar |

## Platform floors

| Platform | Minimum |
|---|---|
| iOS | 18.0 |
| Android | 12 (API 31) |

The Android floor gives every renderer real background blur (`RenderEffect`),
display corner and cutout geometry, stretch overscroll and dynamic color.
On an older device the Android SDK does not start: `App8.instance(...)` throws
`App8Error.UnsupportedPlatform`, and the host shows its own native fallback.

An app can raise its own floor in `app.json`:

```json
{
  "app": { "name": "Shop" },
  "platforms": {
    "ios": { "minVersion": "18.0" },
    "android": { "minSdk": 33 }
  }
}
```

Floors only go up. Below the app's floor the SDK reports
`App8Error.UnsupportedPlatform` the same way.

## Per-node platform overrides

Any component node may carry an `ios` or `android` object. On that platform
the object is merged over the node before decoding (objects merge key by key,
arrays and scalars replace). On the other platform it is ignored.

```json
{
  "type": "icon",
  "content": {
    "properties": { "type": "symbol", "name": "heart.fill" },
    "android": { "properties": { "name": "favorite" } }
  }
}
```

A node can also exist on one platform only:

```json
{ "type": "view", "platforms": ["android"], "content": { } }
```

Overrides are meant for platform conventions, not for designing two apps.
Prefer one definition.

## Icons

SF Symbols are licensed for Apple platforms only, so the Android SDK never
draws them. An `icon` with `type: "symbol"` resolves on Android in this order:

1. The node's `android` override (`properties.name` as a Material Symbols name).
2. The SDK's built-in table from SF Symbol names to Material Symbols names
   (`symbols/sf-to-material.json` in this repo).
3. Nothing: the icon renders empty and the SDK reports a diagnostics warning
   `icon.unmapped`.

## Feature matrix

`✓` supported, `—` not on this platform, `planned` designed but not built yet.
A new DSL feature lands only when both columns are filled (see
[versioning](../VERSIONING.md)).

| Feature | iOS | Android | Notes |
|---|---|---|---|
| `view`, `label`, `image`, `icon`, `button`, `shape` | ✓ | planned | |
| `stackView`, `scrollView`, `collection`, `pageControl` | ✓ | planned | |
| `textField`, `textView`, `toggle`, `slider`, `picker`, `datePicker` | ✓ | planned | Android pickers use Material 3 pickers |
| `activityIndicator`, `shimmer` | ✓ | planned | |
| `video` | ✓ | planned | Media3 |
| `tableView` | ✓ | planned | Rendered as a lazy list with grouped sections |
| `map` | ✓ | planned | Google Maps Compose |
| Layout constraints, priorities, hugging, compression | ✓ | planned | Android solves the same constraints with a Cassowary solver |
| `button` system styles `glass`, `prominentGlass` | ✓ | planned | Android draws glass with blur + tint |
| `material.visualEffect` blur | ✓ | planned | |
| Sheet `detents` `medium`, `large`, number, `NN%` | ✓ | planned | Android bottom sheet anchors |
| `openURL` presentation `sheet` | ✓ | planned | Custom Tabs |
| `haptic` styles | ✓ | planned | Nearest `HapticFeedbackConstants` |
| Per-node `ios` / `android` overrides | planned | planned | DSL 1.1 |
| `app.platforms` floors | planned | planned | DSL 1.1 |
