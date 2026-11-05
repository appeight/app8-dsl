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
| Navigation bar search (`navigationBar.search`) | `UISearchController` (iOS 26 integrated field) | Material 3 search input field in the top app bar (title slot, own row for `stacked`, expanding action for `integratedButton`) |
| Screen transitions (`transition`) | Custom `UIViewControllerAnimatedTransitioning` | Navigation 3 entry animations; predictive back scrubs the authored pop |
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

## Image formats

PNG, JPEG, WebP and GIF work everywhere. AVIF decodes on iOS 16+ and on
Android 14+ only: Android 12 and 13 cannot decode it, and the image stays
empty with an `image` diagnostics warning. Ship PNG, JPEG or WebP for apps
that support the Android floor.

## Feature matrix

`✓` supported, `—` not on this platform, `planned` designed but not built yet.
A new DSL feature lands only when both columns are filled (see
[versioning](../VERSIONING.md)).

| Feature | iOS | Android | Notes |
|---|---|---|---|
| `view`, `label`, `image`, `icon`, `button`, `shape` | ✓ | planned | |
| `stackView`, `scrollView`, `collection`, `pageControl` | ✓ | planned | |
| `textField`, `textView` | ✓ | ✓ | Brand look from DSL styles on both. Android: `BasicTextField`, IME `keyboardType`/`returnKeyType`, `textContentType` → autofill hints, `focus`/`blur` triggers, Material selection handles. See [Input controls](#input-controls) |
| `toggle`, `slider` | ✓ | ✓ | Android: Material 3 `Switch` / `Slider` tinted by the DSL colors, laid out at the iOS size (51×31, 31pt tall) |
| `picker` | ✓ | ✓ | `menu`: pop-up button + Material 3 exposed dropdown menu; `segmented`: Material 3 segmented buttons |
| `datePicker` | ✓ | ✓ | `compact`: pills opening the Material 3 date / time picker dialogs; `inline`: Material 3 `DatePicker`; `wheels`: snapping wheel columns |
| `activityIndicator` | ✓ | ✓ | Android: Material 3 `CircularProgressIndicator` at the iOS sizes (20pt, 37pt `large`), gray by default |
| `shimmer` | ✓ | ✓ | Same sweep on both: 0 → 30% → 0% white band, linear, `duration` (1.5s) |
| `video` | ✓ | ✓ | Android: Media3 ExoPlayer; same events, marks, posters and end behaviors |
| `focus`, `focusNext`, `focusPrevious`, `dismissKeyboard` actions | ✓ | ✓ | |
| `keyboard` layout target | ✓ | ✓ | Android tracks the IME insets |
| `tableView` | ✓ | planned | Rendered as a lazy list with grouped sections |
| `map` | ✓ | ✓ | iOS: MapKit. Android: a pluggable `App8MapProvider`; the optional `engine-maps` module draws Google Maps (host supplies the API key). Without a provider: a static tile with pins and a `map.provider.missing` warning |
| `navigationBar.search` | ✓ | ✓ | `bindVariable` written on every edit, `onSubmit` on the search key. `hidesWhenScrolling` not yet on Android |
| Screen transitions: presets, custom keyframes, `raise`, `reverse`, registry, screen/app defaults | ✓ | ✓ | Android: per-entry keyframes on Navigation 3; `system` keeps the platform animation; predictive back seeks the pop animation |
| Shared-element transitions (`shared`, element `key`, `morph`, `stagger`) | ✓ | ✓ | Android: `SharedTransitionLayout` `sharedBounds` (`frameFade`) / `sharedElement` (`frame`) |
| Custom modals (`mode: modal`): `dimming`, `interactive`, sized `presentation` (`popup`, `sheet`) | ✓ | ✓ | Android: drag tracks 1:1, edge sheets stretch, system back scrubs the dismissal. The presenting screen's `from` keyframes do not animate under a modal yet |
| `hidesTabBar` | ✓ | ✓ | |
| `scrollView` `pagingEnabled`, `autoScroll` | ✓ | ✓ | Android: page-snapping fling; marquee drawn as a second copy after `loopGap` |
| Focused input scrolls above the keyboard | ✓ | ✓ | 20pt gap; Android also extends scroll content by the covered part (hosts use `adjustResize`) |
| Streaming (`streamScreen`, `streamDatasource`, `streamStyles`) | ✓ | ✓ | Datasource updates recompose only readers; screen updates keep variable state |
| `layout.conflict` diagnostics (broken required constraint) | ✓ | ✓ | Names the views the broken constraint relates |
| Layout constraints, priorities, hugging, compression | ✓ | planned | Android solves the same constraints with a Cassowary solver |
| `button` system styles `glass`, `prominentGlass` | ✓ | planned | Android draws glass with blur + tint |
| `material.visualEffect` blur | ✓ | planned | |
| Sheet `detents` `medium`, `large`, number, `NN%` | ✓ | planned | Android bottom sheet anchors |
| `openURL` presentation `sheet` | ✓ | planned | Custom Tabs |
| `haptic` styles | ✓ | planned | Nearest `HapticFeedbackConstants` |
| Per-node `ios` / `android` overrides | planned | planned | DSL 1.1 |
| `app.platforms` floors | planned | planned | DSL 1.1 |

## Android system colors

Material 3 chrome on Android (top app bar search field, `tabBarScreen`
navigation bar, sheets, dialogs, pickers, pull-to-refresh, ripple) takes its
colors from the app, never from Material's baseline scheme (purple seed
`#6750A4`, lavender surfaces like `#F3EDF7`). Both Android renderers (the
native SDK and Shoppu Studio) build the same M3 `ColorScheme` with the same
function, so one JSON gives one brand look.

**Accent** (primary, secondary, tertiary), first match wins:

1. The component's own DSL color: `navigationBar.tintColor`, then
   `navigationBar.search.tintColor` re-theme that screen's chrome; a
   `tabBarScreen` `tintColor` re-themes its tabs.
2. The app's accent: the tab bar `tintColor` (the DSL has no app-level tint),
   which also themes chrome outside the tabs (sheets, dialogs).
3. None: a neutral near-black (`#262626`; `#D9D9D9` in dark). No purple.

**Surfaces** are neutral steps from the system background (white, or black in
dark) toward the label color, the same hue as the background:

| Role | Light | Dark |
|---|---|---|
| `surface`, `background` | `#FFFFFF` | `#000000` |
| `surfaceContainerLow` | `#F7F7F7` (3%) | `#121212` (7%) |
| `surfaceContainer` (navigation bar) | `#F2F2F2` (5%) | `#1C1C1C` (11%) |
| `surfaceContainerHigh` (search field) | `#EBEBEB` (8%) | `#262626` (15%) |
| `surfaceContainerHighest` | `#E3E3E3` (11%) | `#303030` (19%) |
| `onSurface` | label `#000000` | label `#FFFFFF` |
| `onSurfaceVariant` (search icon, placeholder) | `#666666` (60%) | `#999999` (60%) |
| `primaryContainer`, `secondaryContainer` | accent 14% from the background | same |
| `error` | `systemRed` | `systemRed` |

Mixing is per sRGB channel, rounded to 8 bits; `onPrimary` is black or white
by the accent's luminance. Elevation adds no tint (`surfaceTint` is clear).

**Navigation bar items** keep the DSL tab colors, like iOS: selected
`tintColor` (default system blue), unselected `unselectedColor` (default
system gray). The selected indicator pill is the selected color at 14% alpha.

**Light and dark** follow the app's appearance (`userInterfaceStyle`, then
`defaultUserInterfaceStyle`, then the system); `{light, dark}` DSL colors
resolve for that appearance before the scheme is built.

**Dynamic color** (wallpaper palette) is off. A native host can opt in with
`App8Config(dynamicColor = true)`; the app's tints then no longer re-theme
chrome. Studio always draws the app's colors.

Where the DSL sets a color explicitly (tab bar tint and unselected color,
navigation bar and search tint), Android uses that exact color, as iOS does.

## Input controls

Text inputs are brand content: their fill, border, corners, fonts, colors, padding
and placeholder come from DSL styles on both platforms. Everything the operating
system owns follows the platform:

| Concern | iOS | Android |
|---|---|---|
| Keyboard | `keyboardType` → `UIKeyboardType` | `keyboardType` → IME keyboard type (`numberPad` → number, `decimalPad` → decimal, `URL`/`webSearch` → URI, `phonePad` → phone, `emailAddress` → email) |
| Return key | `returnKeyType` | IME action (`next`, `done`, `go`/`join`/`route`/`continue` → go, `search`/`google`/`yahoo` → search, `send`) |
| Return pressed | `tap` actions, then the field resigns | Same; focus stays wherever the actions moved it |
| Autofill | `textContentType` | Android autofill content types (`username`, `password`, `newPassword`, `oneTimeCode` → SMS OTP, names, address, card, birth date) |
| Secure entry | Dots | Dots (password transformation) |
| Clear button | `clearButtonMode` | Same modes, drawn like the iOS button |
| Cursor color | `tintColor` | `tintColor` |
| Keyboard avoidance | `keyboard` constraint target | `keyboard` constraint target, from IME insets |
| Toggle, slider | `UISwitch`, `UISlider` | Material 3 `Switch`, `Slider` (steps finer than 10 stops slide without tick marks) |
| Pickers | `UIMenu` pop-up button, `UISegmentedControl` | Exposed dropdown menu, segmented buttons |
| Date picker | `UIDatePicker` compact / inline / wheels | Pills + Material 3 dialogs / Material 3 `DatePicker` / wheel columns |

A `datePicker` writes `yyyy-MM-dd` to its `bindVariable` in every mode on both
platforms (iOS behavior; time-of-day is not written).
