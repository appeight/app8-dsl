# TabBarScreen

Tab-based navigation container.

## Content Properties

| Property | Type | Description |
|----------|------|-------------|
| `tabs` | Tab[] | Tab definitions |
| `initialTab` | string | Initial tab ID |
| `tintColor` | Color | Selected tab color |
| `unselectedColor` | Color | Unselected tab color |
| `badgeColor` | Color | Badge background (default system red) |
| `badgeTextColor` | Color | Badge text (default white) |
| `selectionIndicatorColor` | Color | Platform bar only: the selected item's highlight (iOS 26 glass bar selection, Android Material 3 indicator pill, web in both modes). Any colour, alpha included (`#00000014`, `rgba(...)`). Default: black at 10% opacity on a light bar, white at 10% on a dark bar. A `barStyle` bar keeps its own `indicatorColor`. Since 0.7.9 |
| `barStyle` | BarStyle | Optional: draw the bar differently or replace it with a component template. See [Bar style](#bar-style). Without it the platform bar is drawn (default). Since 0.7.8. |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | Hide component; see [Visibility](../components.md#visibility) |

## Tab Structure

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique tab identifier |
| `label` | string | Tab label text |
| `icon` | string | SF Symbol name |
| `screen` | string | Screen ID to display |
| `badge` | string/expression | Badge value; empty or `0` hides it |
| `badgeColor` | Color | This tab's badge background |

## Example

<!-- @dsl-type: Component -->
```json
{
  "type": "tabBarScreen",
  "content": {
    "tabs": [
      { "id": "home", "label": "Home", "icon": "house.fill", "screen": "homeScreen" },
      { "id": "search", "label": "Search", "icon": "magnifyingglass", "screen": "searchScreen" },
      { "id": "favorites", "label": "Favorites", "icon": "heart.fill", "screen": "favoritesScreen" },
      { "id": "profile", "label": "Profile", "icon": "person.fill", "screen": "profileScreen" }
    ],
    "initialTab": "home",
    "tintColor": "#007AFF",
    "unselectedColor": "#8E8E93",
    "badgeColor": "#2D4D3A",
    "badgeTextColor": "#FFFFFF",
    "selectionIndicatorColor": "#2D4D3A1F"
  }
}
```

### Selection indicator colour

> Since 0.7.9 on iOS, Android and the web renderer. Engines up to 0.7.8 draw
> the platform's own highlight (a grey on iOS 26, `secondaryContainer` on
> Android) and ignore the key.

`selectionIndicatorColor` paints the highlight behind the selected item of the
platform bar:

| Platform | What it colours |
|----------|-----------------|
| iOS 26 | The glass bar's selection pill behind the selected item (it moves with the selection; while a finger drags across the bar the system's clear lens shows) |
| iOS 18 and earlier | Only when the key is set: a rounded highlight behind the selected item (the bar draws none of its own, and none is added by default) |
| Android | The Material 3 navigation bar's indicator pill |
| Web | The selection pill in iOS mode, the indicator pill in Android mode |

Without the key the highlight is black at 10% opacity when the bar is light and
white at 10% when it is dark (dark mode, or a dark bar background), so a brand
tint is never mixed with the platform grey. Write the colour with alpha for a
tinted highlight (`#1D1D1D1A`), or an opaque colour for a solid pill (then pick
`tintColor` so the selected icon reads on it).

## Bar style

> Since 0.7.8 on iOS, Android and the web renderer. Engines up to 0.7.7 ignore
> `barStyle` and draw the platform bar.

For apps whose voice the system bar does not fit. The system bar stays the
default; every key is optional. A styled or custom bar keeps the bar's place,
the bottom safe area, hide-on-push (`hidesTabBar`), badges, the selection
haptic and the tab accessibility traits: only its drawing changes.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `variant` | string | `system` | `system`: the platform bar (iOS `UITabBar`, Android Material 3 navigation bar). `text`: labels only, no icons, a thin bar. |
| `background` | string / style id | `glass` | `glass`: the platform material (iOS 26 glass, Material 3 surface container). `solid`: the screen's background colour. Or the id of a fill / material style entity. |
| `selection` | string | `capsule` | How the selected tab shows (`text` variant and `component` bars): `capsule` (a pill behind the label that slides between items), `underline` (a 2 pt bar under the label that slides), `box` (a rectangle behind the label that slides), `opacity` (no shape: the selected label at full opacity, the others at `unselectedOpacity`, cross-fading). |
| `text` | text style ref | platform | Label style (`{ "id": "<text style>" }` or inline), so the bar can use the brand's type. |
| `selectedText` | text style ref | `text` | Label style of the selected tab. |
| `unselectedOpacity` | number 0–1 | 0.5 | Opacity of unselected labels with `selection: opacity`. |
| `indicatorColor` | Color | `tintColor` | Colour of the capsule, underline or box. |
| `shape` | string | `floating` | Since 0.7.11. `floating`: a bar inset from the screen's sides and sitting on the bottom safe area, like the iOS 26 tab bar. With `background: "glass"` it is the platform bar itself (iOS 26 glass capsule; Android and earlier iOS their own bar). With any other background (`solid`, a hex colour, a fill style) the engine draws it on every platform: same side insets as the iOS 26 bar (21 pt from each screen edge, 16 dp on Android), its bottom edge 8 pt above the bottom safe area (home indicator / gesture bar), no glass, no shadow, `cornerRadius` corners, exact `height`. `edge`: a full-width stripe with square corners, flush with the screen's bottom edge, its background under the home indicator, exact `height`. Engines up to 0.7.10 draw the platform bar |
| `cornerRadius` | number | half the height | Since 0.7.11. Corner radius of an engine-drawn `floating` bar (non-glass background): `0` is a rectangle, the default a capsule. Ignored for glass and `edge` |
| `badgePlacement` | string | `corner` | Since 0.7.11. `corner`: the badge sits above the end of the label (or icon), as on the system bar. `inline`: the badge follows the label on the same line, vertically centred, 4 pt after it, and the label and badge are centred together in the tab's slot. Text bars and engine-drawn bars; the platform bar keeps `corner` |
| `height` | number | platform | Bar height. Platform (glass) bar: a request, at least 44; a platform whose system bar has a fixed height (iOS) keeps it. Engine-drawn bar (`edge`, or `floating` with a non-glass background): at least 28 and honoured exactly; the tab screens' bottom safe area grows to the bar's top edge, so scroll content ends above it |
| `component` | string | — | A component template that draws the whole bar (see below). `variant` is ignored; `background` still applies. |

The selection is instant; the indicator moves with a cubic ease-out of
0.3 s that a new tap retargets from where it is. Each tab gets an equal slot;
the indicator centres on the selected slot and sizes to its label (capsule:
label width + 28, at most 34 tall; box: label width + 20, at most 28 tall,
square corners; underline: the label's width, 2 pt, 5 pt under it).
`indicatorColor` defaults to `tintColor`; a capsule without one is the tint
at 12% opacity, a faint pill like the system's.
Labels take their colour from `text` / `selectedText`; without a text style
they use `tintColor` (selected) and `unselectedColor`. `height` is a request:
a platform whose system bar has a fixed height (iOS) keeps it.

### Flat bars

Brands whose voice is flat and square (streetwear, editorial) get a bar the
engine draws instead of glass. A floating black rectangle, half the system
height, labels in white, the selected one at full opacity, badges inline:

```json
"barStyle": {
  "variant": "text", "shape": "floating", "background": "#000000", "cornerRadius": 0,
  "height": 32, "selection": "opacity", "unselectedOpacity": 0.3,
  "text": { "id": "tabLabelOnDark" }, "badgePlacement": "inline"
}
```

with `badgeColor: "#FFFFFF"` and `badgeTextColor: "#000000"` so badges read on
the dark bar. `shape: "edge"` makes the same bar a full-width stripe flush with
the bottom edge.

### Custom bar component

`barStyle.component` names a template in `components/`. It is laid out in the
bar's slot (full width, `height` tall, above the bottom safe area) with this
scope:

| Variable | Description |
|----------|-------------|
| `tabs` | `[{ id, label, icon, badge, index }]`, the tabs as declared, `badge` resolved |
| `selectedTab` | id of the selected tab |
| `selectedIndex` | its index |
| `selectionProgress` | fractional index that animates from the old index to the new one (0.3 s cubic ease-out), for an indicator the template moves itself (`transformTranslateX`) |

Items select a tab with `selectTab` (below); give them `accessibility.traits: ["tab"]` so they read as tabs.

### Selecting a tab

Items select a tab with the existing [`selectTab`](../actions.md#select-tab)
action: `{ "type": "selectTab", "tabId": "{{item.id}}" }` (or `tabIndex`).

### Example

<!-- @dsl-type: Component -->
```json
{
  "type": "tabBarScreen",
  "content": {
    "tabs": [
      { "id": "home", "label": "HOME", "icon": "house", "screen": "homeScreen" },
      { "id": "shop", "label": "SHOP", "icon": "square.grid.2x2", "screen": "shopScreen" },
      { "id": "bag", "label": "BAG", "icon": "bag", "screen": "bagScreen", "badge": "{{length(cart)}}" }
    ],
    "tintColor": "#000000",
    "unselectedColor": "#000000",
    "barStyle": {
      "variant": "text",
      "background": "glass",
      "selection": "opacity",
      "text": { "id": "tabLabel" },
      "unselectedOpacity": 0.45
    }
  }
}
```
