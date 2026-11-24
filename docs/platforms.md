# Platforms

The App8 DSL renders natively on iOS (UIKit, `app8-ios-sdk`) and Android
(Jetpack Compose, `app8-android-sdk`). One JSON app runs on both. This page
lists what differs between the platforms and how an app says so.

## Principle: app content identical, system chrome native

Everything an app designs itself renders the same on both platforms: views,
labels, images, shapes, materials, colors, fonts, corner radii, layout and
animations. Parts that belong to the operating system follow that system's
conventions, so the app feels at home on each:

| Concern | iOS | Android |
|---|---|---|
| Navigation bar | `UINavigationBar`, large titles, chevron back button | Material 3 top app bar (64dp; `navigationBar.topAppBar` picks `small`, `centerAligned`, `medium` or `large`), arrow back button. Transparent at rest, `surfaceContainer` once content scrolls under it (no blur, no shadow). Over a hero (`topEdgeEffect: hidden`): icons on legibility circles until the hero scrolls away; with any other `topEdgeEffect` over a hero drawn under the bar, the same circles while the bar is at rest. A root screen (first screen of a tab, flow or modal) whose bar has no title, `titleView`, items or search draws no bar, only the status bar inset. Icon buttons carry TalkBack labels (back arrow "Navigate up"; items their `label`, else a name from the symbol) |
| Navigation bar search (`navigationBar.search`) | `UISearchController` (iOS 26 integrated field) | Material 3 app bar with search (56dp field, 4dp above and below, `surfaceContainer` once content scrolls under it; with `hidesWhenScrolling: true` it hides on scroll down and returns on scroll up); own row for `stacked`; expanding action for `integratedButton` |
| Screen transitions (`transition`) | Custom `UIViewControllerAnimatedTransitioning` | Authored transitions on Navigation 3; `system` is Material shared axis X (450ms). The incoming screen is loaded before the transition starts, so it never fades in from blank. Predictive back scrubs the authored pop, or previews `system` the Material way (90% scale, drift, rounded corners) |
| Back navigation | Edge swipe | System back gesture with predictive back preview |
| Bottom bar (`bottomBar`, `style.background: "system"`) | iOS 26: no fill, system bottom scroll-edge effect (`soft` / `hard`); iOS 18 to 25: toolbar appearance (blur and hairline while content is under it) | Material 3 bottom app bar surface: transparent at rest, `surfaceContainer` once content scrolls under it |
| Tab bar (`tabBarScreen`) | `UITabBar` (floating glass capsule on iOS 26) | Material 3 Expressive short navigation bar (64dp; icon beside label from 600dp wide) |
| Tab switch | Instant | Material fade through (300ms). Both keep each tab's screens and state, so a revisit is not rebuilt |
| Full-screen cover dismiss (`fullScreen` without a custom transition) | Slides down | Slides down and fades (250ms) |
| Press feedback (`button`) | Highlight and dim | Ripple |
| Press feedback (tappable views, collection cells) | None unless the component defines a `touchDown` state | Bounded ripple clipped to the view's corners. A `touchDown` state replaces it (brand looks render the same on both platforms); one that changes only `alpha` keeps the ripple too |
| Scroll edges | Rubber band and bounce | Stretch overscroll |
| Scroll indicators | Thin overlay bars that fade. Vertical lists and scroll views show one by default; horizontal collections and horizontal sections only with `showsScrollIndicator: true` | None |
| `system` font | SF Pro | Roboto (Google Sans on Pixel when available) |
| `corner.curve: continuous` | Continuous (squircle) corners | Continuous corners, drawn as a path |
| Sheets (`presentation: sheet`) | `UISheetPresentationController` | Material 3 modal bottom sheet: `surfaceContainerLow`, the large detent starts at the status bar (no 10pt gap, nothing scales behind it) |
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

A screen takes overrides the same way, in `content.android` / `content.ios`
(or on the screen node). They are merged before the screen is read, so they can
change the `navigationBar`, for example to put a sheet's close button where each
platform has it:

```json
{
  "type": "screen",
  "content": {
    "navigationBar": {
      "leftAction": { "label": "Clear", "action": { "type": "updateVariable", "variableName": "f", "value": "" } },
      "rightAction": { "icon": "xmark", "action": { "type": "dismiss" } }
    },
    "android": {
      "navigationBar": {
        "leftAction": { "icon": "xmark", "label": null, "action": { "type": "dismiss" } },
        "rightAction": { "label": "Clear", "icon": null, "action": { "type": "updateVariable", "variableName": "f", "value": "" } }
      }
    }
  }
}
```

A `null` in an override removes the key. The web renderer applies screen
overrides since 0.7.9 (it used the iOS `navigationBar` in Android mode before);
Android always did, and iOS does since 0.7.9.

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

The Android SDK bundles only the Material Symbols it maps, plus a short allowlist
(`engine/extra-icons.txt` in app8-android-sdk: engine chrome and common names such
as `more_vert`, `expand_more`, `menu`), not the full font. An `android` override that
names a Material Symbol outside that set renders empty and reports
`icon.unavailable`; add the name to `extra-icons.txt` and regenerate the font with
`scripts/subset-icons.py` to ship it.

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
| `textField`, `textView` | ✓ | ✓ | Look from DSL styles on both. Android: `BasicTextField`, IME `keyboardType`/`returnKeyType`, `textContentType` → autofill hints, `focus`/`blur` triggers, Material selection handles. See [Input controls](#input-controls) |
| `toggle`, `slider` | ✓ | ✓ | Android: Material 3 `Switch` / `Slider` tinted by the DSL colors, laid out at the iOS size (51×31, 31pt tall) |
| `picker` | ✓ | ✓ | `menu`: pop-up button + Material 3 exposed dropdown menu; `segmented`: Material 3 segmented buttons |
| `datePicker` | ✓ | ✓ | `compact`: pills opening the Material 3 date / time picker dialogs; `inline`: Material 3 `DatePicker`; `wheels`: snapping wheel columns |
| `activityIndicator` | ✓ | ✓ | Android: Material 3 `CircularProgressIndicator` at the iOS sizes (20pt, 37pt `large`), gray by default |
| `shimmer` | ✓ | ✓ | Same sweep on both: 0 → 30% → 0% white band, linear, `duration` (1.5s) |
| `video` | ✓ | ✓ | Android: Media3 ExoPlayer; same events, marks, posters and end behaviors |
| `native` (host module, props, events → actions with `event`, `native.<module>.<event>` on the bus, `fallback`) | ✓ | ✓ | Android: `App8Config(nativeComponents = …)` with `App8NativeComponent`. Web renderer: `registerNativeComponent` |
| `native` visibility (iOS `isVisible` / `onVisibilityChange`, Android `isVisible`, `appear` / `disappear` actions) | ✓ | ✓ | Visible only on the topmost presented screen of the selected tab, in the foreground, on screen and not hidden; `true` after the appear transition, `false` when a disappear transition starts. Web renderer: `visible` (`live` deprecated). DSL 0.6.3 |
| `bottomBar` (`component`, `insets`, `style.background`, `edgeEffect`, `hidden`) | ✓ | ✓ | Height added to the bottom safe area; above the tab bar when one is shown; `hidden` animates 0.33 s cubic ease-out. Web renderer: iOS edge blur / M3 surface per mode. DSL 0.6.3 |
| `focus`, `focusNext`, `focusPrevious`, `dismissKeyboard` actions | ✓ | ✓ | |
| `keyboard` layout target | ✓ | ✓ | Android tracks the IME insets |
| `tableView` | ✓ | planned | Rendered as a lazy list with grouped sections |
| `map` | ✓ | ✓ | iOS: MapKit. Android: a pluggable `App8MapProvider`; the optional `engine-maps` module draws Google Maps (host supplies the API key). Without a provider: a static tile with pins and a `map.provider.missing` warning |
| `navigationBar.search` | ✓ | ✓ | `bindVariable` written on every edit, `onSubmit` on the search key. Android: `hidesWhenScrolling: true` hides the search app bar on scroll (enterAlways); a stacked search row does not hide yet |
| Screen transitions: presets, custom keyframes, `raise`, `reverse`, registry, screen/app defaults | ✓ | ✓ | Android: per-entry keyframes on Navigation 3; `system` keeps the platform animation; predictive back seeks the pop animation |
| Shared-element transitions (`shared`, element `key`, `morph`, `stagger`) | ✓ | ✓ | Android: `SharedTransitionLayout` `sharedBounds` (`frameFade`) / `sharedElement` (`frame`) |
| Custom modals (`mode: modal`): `dimming`, `interactive`, sized `presentation` (`popup`, `sheet`) | ✓ | ✓ | Android: drag tracks 1:1, edge sheets stretch, system back scrubs the dismissal. The presenting screen's `from` keyframes do not animate under a modal yet |
| `hidesTabBar` | ✓ | ✓ | |
| Tab `badgeColor`, `badgeTextColor` | ✓ | ✓ | iOS `UITabBarItem.badgeColor`; Android `Badge` colors |
| `picker` menu look (`style.label`, `indicator`), `bindKey` | ✓ | ✓ | iOS plain `UIButton` pull-down with `UIMenu`; Android text + icon anchoring `DropdownMenu` |
| `contextMenu` (preview, items, `onPreviewTap`) | ✓ | ✓ | iOS `UIContextMenuInteraction`; Android long press opens a quick-view `ModalBottomSheet` |
| `scrollView` zoom (`minimumZoomScale`, `maximumZoomScale`, `doubleTapZoom`) | ✓ | ✓ | Android: telephoto `zoomable` |
| `scrollView` `stretchesTopChild` | ✓ | ✓ | The hero (first child, descending into containers) grows by the pull; only its background scales, its other children keep their constraints (0.7.14; 0.7.11 scaled the whole hero) |
| `scrollView` `contentInsetAdjustment: bottom` | ✓ | ✓ | Only the bottom edge follows the safe area (0.7.11) |
| `tabBarScreen` engine-drawn bar (`shape`, `cornerRadius`, `badgePlacement`, exact `height`) | ✓ | ✓ | Non-glass background: floating (inset, any corners) or edge stripe (0.7.11) |
| `contextMenu.preview.cornerRadius` | ✓ | ✓ | iOS `UIPreviewParameters.visiblePath`; Android sheet preview clip (0.7.11) |
| `zoom` transition with `sourceKey` | ✓ | ✓ | iOS 18 `preferredTransition = .zoom`; Android `sharedBounds` + predictive back |
| Persisted app variables (`persist`) | ✓ | ✓ | iOS `UserDefaults`; Android DataStore |
| Object key access in expressions (`map[key]`) | ✓ | ✓ | |
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
| Vertical paging collection (`pagingStyle: paging`, `itemHeight: "fill"`, `currentPageVariable` on `type: vertical`) | ✓ | ✓ | One page per swipe or flick, no automatic safe-area insets. iOS: `isPagingEnabled` when a page is the frame, else a one-page snap; Android: `VerticalPager` with `PagerSnapDistance.atMost(1)`. Web renderer: one page per wheel notch or trackpad swipe |
| `if` action (`condition`, `then`, `else`) | ✓ | ✓ | Condition evaluated once with the [boolean coercion](variables.md#boolean-coercion); an unevaluable condition runs `else`. Web renderer: same rules |
| One [boolean coercion](variables.md#boolean-coercion) for every boolean (`if`, `isHidden`, `isEnabled`, toggles, …) | ✓ | ✓ | Android before this release read `"yes"` as true and other strings as unset. Web renderer: same rule |
| `stackView` `style.layoutMargins` (`top`, `leading`, `bottom`, `trailing`) | ✓ | ✓ | iOS `directionalLayoutMargins` + `isLayoutMarginsRelativeArrangement`; Android and web renderer: margins in the stack's solver constraints |
| `sortBy(array, key, ascending)`, `merge(a, b)` expression functions | ✓ | ✓ | Shared input/output table in the conformance repo (`fixtures/functions/sortBy-merge.json`), run by each renderer's tests |
| `startOfWeek(date)`, `weekdayIndex(date)` expression functions (0.7.16) | ✓ | ✓ | First weekday of the device region: iOS `Calendar.autoupdatingCurrent.firstWeekday` (honours the user's first-day setting); Android `WeekFields` of the default format locale (a `-u-fw-` preference wins). Web renderer: `Intl.Locale` week info, with a CLDR fallback table where the browser has none (Firefox). Shared input/output table for en-US, en-GB and de-AT in the conformance repo (`fixtures/functions/week-start.json`), run by each renderer's tests |
| Array and object literals in expressions (`[…]`, `{key: value}`, nested braces) | ✓ | ✓ | Web renderer: same grammar |
| Expressions in `navigationBar.title` (live updates) | ✓ | ✓ | Web renderer: iOS and Android bars |
| Expressions in bar items' `icon`, `label`, `color` (live updates); `action` as an array | ✓ | ✓ | `leftAction`, `rightAction`, `rightActions`. iOS updates the `UIBarButtonItem` in place (symbol replace transition); Android recomposes the top app bar item. Web renderer: iOS and Android bars |
| `image` source without `type` (`url` → remote, `asset` / `name` → local) | ✓ | ✓ | Web renderer: same inference |
| Bundle font files on the web renderer (`@font-face` per manifest font with a `file`) | — | — | Web renderer only; native apps already register bundle font files through the host |
| Unknown action types are skipped (one diagnostic, the list and screen go on) | ✓ | ✓ | Earlier iOS and Android releases reject the screen. Web renderer: always skipped |
| Section headers in `grid` collections (`groupBy`, `sectionDefinitions`), `section.items` in header scope | ✓ | ✓ | Web renderer: same |
| `button` `isEnabled` coercion (`false`, `0`, strings other than `"true"`/`"1"` disable) | ✓ | ✓ | Disabled: no actions, no tap analytics; custom path alpha 0.4 on all renderers |
| Photos: `capturePhoto`, `deletePhoto`, `photo://` references in `image`, launch cleanup, removal by `clearPersistedData` ([photos.md](photos.md)) | ✓ | ✓ | iOS: `UIImagePickerController` camera, `PHPickerViewController` library, action sheet chooser. Android: system camera (`ACTION_IMAGE_CAPTURE`), Photo Picker, bottom sheet chooser. Web renderer: in-page `getUserMedia` camera (file input fallback), file input library, IndexedDB storage. Release 0.7.2; 0.7.0 and 0.7.1 skip both actions and draw a `photo://` image empty, earlier iOS/Android releases reject the screen |
| [Unknown and mistyped values](index.md#unknown-and-mistyped-values) are ignored, never fatal (0.7.10; a mistyped value takes its default, the component and screen stay; one `value.ignored` warning per value; out-of-range numbers clamped) | ✓ (0.7.10) | ✓ (0.7.10) | Earlier releases: iOS and the web renderer rejected the screen (iOS error screen) on a mistyped value on the screen's own fields and dropped a whole child for one bad property; Android dropped a whole child, and some inputs (huge sizes, negative insets, inverted ranges, `NaN` numbers, an unregistered collection template id on iOS) crashed. Web renderer: same rules; its editor preview outlines a component that failed to render |
| Screen `userInterfaceStyle` (`light` / `dark` for one screen: content, bar, back button, status bar, alerts and sheets) | ✓ (0.7.10) | ✓ (0.7.10) | iOS: `overrideUserInterfaceStyle` on the screen's view controller, the navigation bar follows the top screen with the push/pop transition. Android: a color scheme per screen for its content, top app bar and dialogs; system bar icons follow the top screen. Web renderer: same, in iOS and Android modes. See [screen.md](components/screen.md#light-and-dark) |
| Per-node `ios` / `android` overrides | ✓ (0.7.9) | planned | DSL 1.1. iOS applies them to raw JSON before decoding: screens, templates and every nested component slot |
| `app.platforms` floors | planned | planned | DSL 1.1 |

Exact Android chrome numbers (heights, paddings, icon sizes, motion) and their
Material sources: `docs/android-chrome-spec.md` in app8-android-sdk. The web renderer's
Android preview draws the same numbers.

## Android system colors

Material 3 chrome on Android (top app bar search field, `tabBarScreen`
navigation bar, sheets, dialogs, pickers, pull-to-refresh, ripple) takes its
colors from the app, never from Material's baseline scheme (purple seed
`#6750A4`, lavender surfaces like `#F3EDF7`). Both Android renderers (the
native SDK and the web renderer) build the same M3 `ColorScheme` with the same
function, so one JSON gives one look.

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

**Navigation bar items**: selected `tintColor` (default the scheme's
`primary`); unselected `unselectedColor` while it reaches 4.5:1 against the
bar's `surfaceContainer` (alpha composited), else `onSurfaceVariant`, so tab
labels stay readable (the iOS gray defaults read 2.3–3:1 there). The selected
indicator pill is the selected color at 14% alpha.

**Screen backgrounds**: a screen without its own `backgroundColor` shows
`surface`; in a bottom sheet it shows the sheet's `surfaceContainerLow`. A
screen's own `backgroundColor` (brand content) is drawn as authored.

**Light and dark** follow the app's appearance (`userInterfaceStyle`, then
`defaultUserInterfaceStyle`, then the system); `{light, dark}` DSL colors
resolve for that appearance before the scheme is built. A screen with its own
`userInterfaceStyle` ([screen.md](components/screen.md#light-and-dark)) gets
its own scheme, built for that style: its content, top app bar, dialogs and
sheets use it, and the status and navigation bar icons follow the screen on
top (light icons over a dark screen).

**Dynamic color** (wallpaper palette) is off. A native host can opt in with
`App8Config(dynamicColor = true)`; the app's tints then no longer re-theme
chrome. The web renderer always draws the app's colors.

Where the DSL sets a color explicitly (tab bar tint, navigation bar and
search tint), Android uses that exact color, as iOS does. The one exception is
an unselected tab color below 4.5:1, replaced as above.

## Input controls

Text inputs are app content: their fill, border, corners, fonts, colors, padding
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
