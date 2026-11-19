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
| `barStyle` | BarStyle | Optional: draw the bar differently or replace it with a component template. See [Bar style](#bar-style). Without it the platform bar is drawn (default). |
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
    "badgeTextColor": "#FFFFFF"
  }
}
```

## Bar style

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
| `height` | number | platform | Bar height above the safe area, at least 44. |
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
