# Navigation

Navigation controls flow between screens using flows, push/pop, modals, and tabs.

## App Structure

```json
{
  "app": {
    "name": "MyApp",
    "variables": { }
  },
  "navigation": {
    "startFlow": "onboarding",
    "flows": [
      { "id": "onboarding", "startScreen": "welcome" },
      { "id": "main", "startScreen": "home" }
    ]
  },
  "screens": {
    "welcome": { },
    "home": { }
  },
  "templates": [ ]
}
```

| Key | Description |
|-----|-------------|
| `app` | App metadata and global variables |
| `navigation` | Flow definitions |
| `screens` | Screen definitions by ID |
| `templates` | Reusable component templates |

---

## Flows

Flows are navigation containers with independent stacks.

### Flow Definition

```json
{
  "navigation": {
    "startFlow": "onboarding",
    "flows": [
      { "id": "onboarding", "startScreen": "welcome" },
      { "id": "main", "startScreen": "home" }
    ]
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `startFlow` | string | Initial flow on app launch |
| `flows` | Flow[] | Array of flow definitions |

### Flow Object

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique flow identifier |
| `startScreen` | string | Initial screen for this flow |

### Switching Flows

Use `completeFlow` to finish current flow and switch:

```json
{
  "type": "completeFlow",
  "destination": "main"
}
```

### Common Flow Patterns

**Onboarding → Main:**
```json
{
  "flows": [
    { "id": "onboarding", "startScreen": "welcome" },
    { "id": "main", "startScreen": "tabBar" }
  ]
}
```

**Auth → App:**
```json
{
  "flows": [
    { "id": "auth", "startScreen": "login" },
    { "id": "app", "startScreen": "dashboard" }
  ]
}
```

---

## Screen Navigation

### Push (Default)

Standard hierarchical navigation with back button.

```json
{
  "type": "navigation",
  "nextScreen": "details"
}
```

### With Parameters

```json
{
  "type": "navigation",
  "nextScreen": "userProfile",
  "params": {
    "userId": "{{selectedUserId}}",
    "showEdit": true
  }
}
```

### Receiving Parameters

Define expected parameters in the screen:

```json
{
  "type": "screen",
  "content": {
    "inputParameters": {
      "userId": { "type": "string", "required": true },
      "showEdit": { "type": "boolean", "required": false }
    }
  }
}
```

Parameters are available as variables:

```json
"text": "{{userId}}"
"hidden": "{{!showEdit}}"
```

---

## Custom Transitions

The presentation styles below cover the built-in system animations. To customize
*how* a screen animates in and out — slide/fade/zoom/cover presets, fully custom
opacity/translate/scale/rotate keyframes, reusable named transitions,
gesture-driven interactive dismiss, **sized modal popups & sheets** (a `presentation`
block sizing the container relatively or absolutely), and **shared-element**
(hero / composite) morphs that grow a matched component into its counterpart on the
next screen — add a `transition` to the navigation action:

```json
{ "type": "navigation", "nextScreen": "detail", "transition": "slide" }
```

See [transitions.md](transitions.md) for the full transition system, including the
`popup` / `sheet` presets for sized modals and the `shared` preset for
shared-element transitions.

## Presentation Styles

### Push (Hierarchical)

Standard navigation push with back button.

```json
{
  "type": "navigation",
  "nextScreen": "details",
  "presentation": "push"
}
```

### Sheet

iOS-style bottom sheet (native `UISheetPresentationController`), with a grabber and
swipe-to-dismiss.

```json
{
  "type": "navigation",
  "nextScreen": "filter",
  "presentation": "sheet",
  "detents": ["medium", "large"]
}
```

**Detents** are the heights the sheet can rest at; supply several to let the user
drag between them. Each entry is one of:

| Form | Meaning |
|------|---------|
| `"medium"` | System half-height detent. |
| `"large"` | System full-height detent. |
| a number, e.g. `320` | Custom detent at a fixed height in points. |
| `"NN%"`, e.g. `"60%"` | Custom detent at a fraction of the largest available height. |

```json
{ "type": "navigation", "nextScreen": "peer", "presentation": "pageSheet",
  "detents": ["60%", "large"], "grabber": false }
```

Omitting `detents` defaults to a single `large` detent. Scrolling the content past
its top grows the sheet to the next detent. Set **`grabber: false`** to hide the
drag indicator (it's shown by default). For a fully custom-styled bottom card (your
own size, corner radius, shadow, and dismiss animation) use the engine-driven
[`sheet` transition preset](transitions.md#sized-modal-presentation-popups--sheets)
instead.

### Full Screen Modal

```json
{
  "type": "navigation",
  "nextScreen": "fullScreenImage",
  "presentation": "fullScreen"
}
```

No swipe to dismiss. Must explicitly dismiss.

### Form Sheet

```json
{
  "type": "navigation",
  "nextScreen": "editItem",
  "presentation": "formSheet"
}
```

Smaller modal, optimized for iPad. Centered with backdrop.

### Page Sheet

```json
{
  "type": "navigation",
  "nextScreen": "settings",
  "presentation": "pageSheet",
  "detents": ["medium", "large"]
}
```

Same native sheet as [Sheet](#sheet) and accepts the same `detents`
(`medium` / `large` / a fixed number / `"NN%"`).

### Cross Dissolve

Full screen modal that fades in instead of sliding up. Good for splash-style transitions and image lightboxes.

```json
{
  "type": "navigation",
  "nextScreen": "photoViewer",
  "presentation": "crossDissolve"
}
```

---

## Navigation Bar

Configure the navigation bar for each screen.

### Structure

```json
{
  "type": "screen",
  "content": {
    "navigationBar": {
      "title": "Profile",
      "titleView": { },
      "titleAlignment": "left",
      "backLabel": "Back",
      "hidden": false,
      "leftAction": { },
      "rightAction": { },
      "rightActions": [ ]
    }
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `title` | string / expression | Navigation bar title (ignored when `titleView` is set). An expression like any text property (`"{{count}} items"`, `"{{selected.name}}"`): it updates when its variables change, large title included |
| `largeTitle` | boolean | Show `title` as a large title: iOS `prefersLargeTitles` (34pt bold under the bar, moving with the content and collapsing into the inline title as it scrolls). Use it for a tab's root screen title instead of a label or a collection row. Needs a plain `title` (no `titleView`, no `search`); `titleColor` applies to the inline title only. Android ignores it: set `topAppBar: "large"` for the same role |
| `titleView` | Component | Custom DSL component rendered as the nav bar title |
| `titleAlignment` | string | `"left"` places `titleView` as left bar item; `"center"` (default) uses standard title area |
| `backLabel` | string | Custom back button label (ignored when `titleView` is set). Like the default back button, it shows only on a pushed screen: the root of a stack (a tab's first screen, a flow's start screen) has none |
| `hidden` | boolean | Hide navigation bar |
| `hidesBackButton` | boolean | Hide the back button on a pushed screen (back swipe still works). For a search screen whose field takes the back button's place; leave the screen with `search.onCancel` |
| `leftAction` | BarAction | Left bar button (ignored when `titleAlignment: "left"`) |
| `rightAction` | BarAction | Single right bar button (kept for backward compatibility) |
| `rightActions` | BarAction[] | Multiple right bar buttons — takes priority over `rightAction` |
| `tintColor` | Color | Back chevron and bar-button tint while this screen is on top (system tint when omitted) |
| `topEdgeEffect` | string | iOS 26 scroll-edge effect under the bar: `automatic` (default), `soft`, `hard`, or `hidden` (e.g. an edge-to-edge hero image under a transparent bar). iOS: hidden at rest; it fades in over 16pt once the hero's bottom (or, without a hero, the first content) reaches the bar's bottom. Android: `hidden` keeps the top app bar transparent over the hero, with icons on legibility circles, until the hero scrolls away; other values turn the bar `surfaceContainer` as soon as content scrolls under it |
| `topAppBar` | string | Android only (iOS ignores it): Material 3 top app bar variant, `small` (default, 64dp), `centerAligned`, `medium` (112dp, collapses to 64dp on scroll) or `large` (152dp, collapses to 64dp). Write it in an `android` override when the iOS bar should stay the same |
| `search` | SearchBar | System search field in the bar — see [Search](#search) |

### Search

`navigationBar.search` attaches the system search field (`UISearchController`) to the
bar. The system draws the field, its glass, the dictation mic, and the cancel (✕)
button that appears only while the field is focused. Never build a search bar from a
`view` + `textField` — use this.

```json
{
  "navigationBar": {
    "search": {
      "placeholder": "Search or ask a question",
      "bindVariable": "searchQuery",
      "placement": "integrated",
      "fillsBar": true,
      "tintColor": "#214E38",
      "onSubmit": { "type": "navigation", "nextScreen": "searchResults", "params": { "q": "{{searchQuery}}" } }
    }
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `placeholder` | string | | Placeholder text (expressions allowed) |
| `bindVariable` | string | | Screen variable kept in sync with the field text as the user types |
| `placement` | string | `automatic` | `automatic`, `stacked` (own row under the title), `inline` (title row), `integrated` (iOS 26: the field fills the bar), `integratedButton` (iOS 26: a search button that expands), `integratedCentered` (iOS 26). iOS 26 values fall back to `inline` on older systems |
| `hidesWhenScrolling` | boolean | `false` | Collapse the field as the content scrolls |
| `tintColor` | Color | | Caret and cancel-button tint |
| `fillsBar` | boolean | `false` | With `placement: "integrated"` (iOS 26): stretch the field across the bar from the leading edge instead of the compact trailing field. While focused it shortens to make room for the ✕ |
| `onSubmit` | Action \| Action[] | | Runs when the user taps the keyboard's search key |
| `mode` | string | `field` | `field`: the editable system field. `button`: the same field, drawn identically (placeholder, glass, magnifier, size), that never takes focus or shows the keyboard; a tap runs `onTap`. Use it on a screen whose search lives on its own screen |
| `onTap` | Action \| Action[] | | `mode: "button"` only: runs on a tap, typically a push to the search screen |
| `autoFocus` | boolean | `false` | Focus the field (keyboard up, cancel ✕ shown) as soon as the screen appears. For a dedicated search screen |
| `onCancel` | Action \| Action[] | | Runs when the user taps the cancel ✕, after the field clears and loses focus. A dedicated search screen pops: `{ "type": "navigation", "isBack": true }` |

A screen with only `search` (no `title`) shows just the field. Do not set `hidden: true`
— that hides the field too.

While focused, the field never leaves the bar's margins: it shortens to make room for the
✕ instead of sliding out past the leading edge, also on a screen with `rightActions`
(the trailing items give way to the ✕ while the field is focused).

#### Search as a button that opens a search screen

A common iOS 26 pattern: a screen shows a search field that is a
button; tapping it pushes a search screen whose field sits in exactly the same place,
already focused, with the keyboard up. The bar items morph between the two screens like
any other push (the field stays put, the content changes underneath), and the field on
the first screen morphs into the back button when a detail screen is pushed.

The first screen (`home`):

```json
{
  "navigationBar": {
    "search": {
      "placeholder": "Search",
      "placement": "integrated",
      "fillsBar": true,
      "mode": "button",
      "onTap": { "type": "navigation", "nextScreen": "search" }
    }
  }
}
```

The search screen (`search`):

```json
{
  "navigationBar": {
    "search": {
      "placeholder": "Search",
      "bindVariable": "query",
      "placement": "integrated",
      "fillsBar": true,
      "autoFocus": true
    }
  }
}
```

Keep `placeholder`, `placement` and `fillsBar` the same on both screens. The search
screen keeps its back button: unfocused, the field sits beside it; focused, the ✕ ends
search (the field unfocuses, the screen stays). Give the screen content of its own so it
never looks empty: recent searches while `query` is empty (an app variable with
`persist: true`, newest first, capped with `slice`), popular items from a datasource, and
live results as the user types. A search screen with nothing else to show can leave on
the ✕ instead: `onCancel: { "type": "navigation", "isBack": true }`, with
`hidesBackButton: true`. Don't repeat the first screen's `rightActions` on the search
screen.

| Platform | Behavior |
|----------|----------|
| iOS | `mode: "button"`: the real `UISearchController` field; `searchBarShouldBeginEditing` returns `false` and runs `onTap` (a tap that activates the controller directly is undone and runs `onTap` too), so it is pixel-identical and the navigation bar morphs it into the next screen's items (back button, the search screen's field) on push and back on pop. `autoFocus` activates the search controller once the push lands; the ✕ is the system cancel button |
| Android | `mode: "button"`: the Material 3 search bar (collapsed), a tap runs `onTap`. The search screen's field is the expanded search view: focused, keyboard up, a ✕ that clears and runs `onCancel` |
| Web renderer | Same as the platform it renders as: the button field has no caret and runs `onTap` on click; `autoFocus` focuses the input on appear |

### Bar Action

```json
{
  "label": "Save",
  "icon": "checkmark",
  "style": "bold",
  "action": { "type": "executeFunction", "function": "save" }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `label` | string / expression | Button text |
| `icon` | string / expression | SF Symbol name (alternative to label). Android draws the matching Material Symbol (`heart.fill` is the filled `favorite`) |
| `style` | string | `"bold"`, `"destructive"` |
| `color` | Color / expression | The button's tint; wins over `style: "destructive"` and the bar's `tintColor`. An expression must give a hex color, else the field is left unset |
| `action` | Action / Action[] | Action, or actions run in order, when tapped |

`icon`, `label` and `color` are expressions like `title`: they resolve in the screen's
scope (screen, then app variables) and update when their variables change, on
`leftAction`, `rightAction` and every item of `rightActions`. A bar heart that follows
a wishlist:

```json
{
  "navigationBar": {
    "title": "{{product.title}}",
    "rightActions": [
      {
        "icon": "{{includes(wishlist, product.handle) ? 'heart.fill' : 'heart'}}",
        "color": "{{includes(wishlist, product.handle) ? '#FF2D55' : '#000000'}}",
        "action": [
          { "type": "toggleArrayValue", "variableName": "wishlist", "value": "{{product.handle}}" },
          { "type": "haptic", "hapticStyle": "light" }
        ]
      }
    ]
  }
}
```

| Platform | Update |
|----------|--------|
| iOS | The same `UIBarButtonItem` gets the new image (SF Symbol replace transition), title or tint in place: the Liquid Glass group is not rebuilt and does not flicker |
| Android | The top app bar item recomposes with the new Material Symbol, text or tint |
| Web renderer | The bar re-renders with the screen, in both iOS and Android modes |

An `icon` that resolves to an empty string draws an empty button. Before 0.7.3, `icon` and
`label` were read as plain text, `color` was resolved once (iOS) and an `action` array
failed the screen on iOS and Android.

### Examples

**Title Only:**
```json
{
  "navigationBar": {
    "title": "Settings"
  }
}
```

**Large Title (a tab's root screen):**
```json
{
  "navigationBar": {
    "title": "Wishlist",
    "largeTitle": true,
    "topAppBar": "large"
  }
}
```

**Hidden:**
```json
{
  "navigationBar": {
    "hidden": true
  }
}
```

**With Actions:**
```json
{
  "navigationBar": {
    "title": "Edit Profile",
    "leftAction": {
      "label": "Cancel",
      "action": { "type": "dismiss" }
    },
    "rightAction": {
      "label": "Save",
      "style": "bold",
      "action": { "type": "executeFunction", "function": "saveProfile" }
    }
  }
}
```

**Custom Back:**
```json
{
  "navigationBar": {
    "title": "Details",
    "backLabel": "List"
  }
}
```

**With Icon:**
```json
{
  "navigationBar": {
    "title": "Settings",
    "rightAction": {
      "icon": "gear",
      "action": { "type": "navigation", "nextScreen": "preferences" }
    }
  }
}
```

**Multiple Right Buttons:**
```json
{
  "navigationBar": {
    "title": "Select Items",
    "leftAction": {
      "label": "Cancel",
      "action": { "type": "dismiss" }
    },
    "rightActions": [
      {
        "icon": "square.and.pencil",
        "action": { "type": "executeFunction", "function": "edit" }
      },
      {
        "icon": "trash",
        "style": "destructive",
        "action": { "type": "executeFunction", "function": "delete" }
      }
    ]
  }
}
```

Note: `rightActions` renders right-to-left — the first item in the array appears rightmost.

**Left-Aligned Title View (avatar + title):**
```json
{
  "navigationBar": {
    "titleView": {
      "id": "navTitleStack",
      "type": "stackView",
      "content": {
        "properties": { "axis": "horizontal", "spacing": 10, "alignment": "center" },
        "children": [
          {
            "id": "navAvatar",
            "type": "image",
            "content": {
              "properties": { "url": "{{user.avatarUrl}}", "contentMode": "scaleAspectFill" },
              "layout": { "width": 36, "height": 36 },
              "style": { "material": [{ "corner": { "radius": 18, "curve": "circular" } }] }
            }
          },
          {
            "id": "navTitleLabel",
            "type": "label",
            "content": {
              "properties": { "text": "{{user.name}}" },
              "style": { "text": { "fontSize": 20, "fontWeight": "bold", "color": "#FFFFFF" } }
            }
          }
        ]
      }
    },
    "titleAlignment": "left",
    "rightActions": [
      { "icon": "magnifyingglass", "action": { "type": "navigation", "nextScreen": "search" } },
      { "icon": "plus", "action": { "type": "navigation", "nextScreen": "newChat" } }
    ]
  }
}
```

---

## Bottom Bar

`bottomBar` pins content to the bottom of a screen the way the navigation bar pins the top: usually one or two primary actions (Save, Play, Continue). The engine lays it out above the bottom safe area, keeps scroll content from resting under it, and gives it the platform's own material behaviour.

### Structure

<!-- @dsl-type: Component -->
```json
{
  "type": "screen",
  "content": {
    "bottomBar": {
      "component": { "id": "barActions", "type": "stackView", "content": { } },
      "insets": { "top": 12, "left": 16, "bottom": 8, "right": 16 },
      "style": { "background": "system" },
      "edgeEffect": "soft",
      "hidden": false
    },
    "children": [ ]
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `component` | Component | required | The bar's content, any DSL component (usually a horizontal or vertical `stackView` of buttons). It reads the screen's variables and runs actions like any other component on the screen |
| `insets` | EdgeInsets | `{ "top": 12, "left": 16, "bottom": 8, "right": 16 }` | Space around `component` inside the bar. `left` / `right` are the leading and trailing edges. `bottom` is measured from the bottom safe area (home indicator, gesture bar or tab bar), not from the screen edge. Each edge is optional; a missing edge keeps its default |
| `style.background` | `"system"` or style entity | `"system"` | `"system"`: the platform's bar treatment, see [Background](#background). Otherwise a `material` or `fill` [style entity](styles.md#using-styles-in-components) (inline or pointer) drawn behind the bar |
| `edgeEffect` | string | `"soft"` | iOS 26 scroll-edge effect for a `"system"` background: `"soft"` or `"hard"`. An unknown value is `"soft"`. Ignored with a custom background and on other platforms |
| `hidden` | [boolean](variables.md#boolean-coercion)/expression | `false` | Hides the bar. Changes animate, see [Hiding](#hiding) |

### Layout

- The bar spans the full width of the screen. `component` is pinned to the bar's `insets` horizontally and vertically; its height is its fitting height (or its own `layout.height`). Other `layout` constraints on `component` are ignored.
- The bar sits directly above the bottom safe area. When the screen shows a tab bar, that is above the tab bar; on a pushed screen with `hidesTabBar`, it is above the home indicator or gesture bar.
- The bar's height (from its top edge to the bottom safe area) is **added to the screen's bottom safe area**. Scroll views and collections that reach the bottom of the screen get the matching bottom content inset, so their last item scrolls up clear of the bar, and anything constrained to `safeArea` bottom stays above it. A screen's own `additionalSafeAreaInsets.bottom` adds on top; it does not move the bar.
- The bar draws above the screen's `children`.
- The keyboard does not move the bar; it covers it like the rest of the bottom of the screen. Use the [`keyboard` layout target](layout.md) for content that must stay above the keyboard.

### Background

`"system"` (the default) follows each platform:

| Platform | `"system"` |
|----------|------------|
| iOS 26 | No fill. Content scrolls under the bar with the system bottom scroll-edge effect (`UIScrollEdgeEffect`, `soft` or `hard` from `edgeEffect`) and the bar's buttons keep their Liquid Glass |
| iOS 18 to 25 | The toolbar appearance: transparent while the scroll content ends above the bar, the system chrome material (blur) with a hairline separator while content is under it |
| Android | Material 3 bottom app bar surface: transparent at rest, `surfaceContainer` once content scrolls under it (animated, no shadow), the same rule as the top app bar ([platforms](platforms.md#android-system-colors)) |
| Web renderer | iOS mode: the iOS bottom edge blur, drawn like the top bar's. Android mode: the Material 3 surface as on Android |

"Content scrolls under it" means the screen's scroll view (the one that reaches the bottom of the screen) can scroll further down than the bar's top edge. A screen that does not scroll has nothing under the bar.

A `material` or `fill` background replaces the system treatment on every platform: it fills the bar from its top edge down to the screen's bottom edge (or to the top of the tab bar), and there is no edge effect or tonal change.

### Hiding

`hidden` takes a boolean or an expression and re-evaluates when its variables change. Hiding slides the bar down by its height while it fades out; showing reverses it. Both take 0.33 s with a cubic ease-out curve, and the bottom safe area shrinks or grows with the same animation. A bar that starts hidden appears without animation the first time the screen shows; it is laid out but takes no space.

### Example

A clip detail screen with two actions. The bar keeps them reachable while the text scrolls under it:

<!-- @dsl-type: Component -->
```json
{
  "type": "screen",
  "content": {
    "navigationBar": { "title": "Clip" },
    "variables": {
      "isSaved": { "type": "boolean", "initialValue": false }
    },
    "bottomBar": {
      "component": {
        "id": "clipActions",
        "type": "stackView",
        "content": {
          "properties": { "axis": "horizontal", "spacing": 12, "distribution": "fillEqually" },
          "children": [
            {
              "id": "saveButton",
              "type": "button",
              "content": {
                "properties": { "text": "{{isSaved ? 'Saved' : 'Save'}}" },
                "style": { "system": { "variant": "glass", "cornerStyle": "capsule", "size": "large" } },
                "layout": { "height": 50 },
                "actions": { "tap": { "type": "updateVariable", "variableName": "isSaved", "value": "{{!isSaved}}" } }
              }
            },
            {
              "id": "playButton",
              "type": "button",
              "content": {
                "properties": { "text": "Play" },
                "style": { "system": { "variant": "prominentGlass", "cornerStyle": "capsule", "size": "large" } },
                "layout": { "height": 50 },
                "actions": { "tap": { "type": "navigation", "nextScreen": "player", "presentation": "fullScreen" } }
              }
            }
          ]
        }
      },
      "edgeEffect": "soft"
    },
    "children": [ ]
  }
}
```

With a custom background and a bar that hides while a note is being edited:

<!-- @dsl-skip: bottomBar fragment -->
```json
"bottomBar": {
  "component": { "id": "noteActions", "type": "stackView", "content": { } },
  "style": {
    "background": {
      "id": "noteBarMaterial",
      "type": "material",
      "content": [
        { "id": "noteBarFill", "type": "fill", "content": { "solid": "#FFFFFF" } }
      ]
    }
  },
  "hidden": "{{isEditing}}"
}
```

`bottomBar` works on any `screen`: the root of a flow, a screen pushed on a navigation stack, a tab's screen and a presented screen. It is not a property of `tabBarScreen`.

---

## Tab Bar

Tab-based navigation using TabBarScreen.

### Structure

```json
{
  "type": "tabBarScreen",
  "content": {
    "tabs": [
      { "id": "home", "label": "Home", "icon": "house.fill", "screen": "homeScreen" },
      { "id": "search", "label": "Search", "icon": "magnifyingglass", "screen": "searchScreen" },
      { "id": "profile", "label": "Profile", "icon": "person.fill", "screen": "profileScreen" }
    ],
    "initialTab": "home",
    "tintColor": "#007AFF",
    "unselectedColor": "#8E8E93"
  }
}
```

### Tab Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique tab identifier |
| `label` | string | Tab label text |
| `icon` | string | SF Symbol name |
| `screen` | string | Screen ID to display |
| `badge` | string | System badge on the tab item; usually an expression over app variables, e.g. `"{{sum(map(cart, item.quantity))}}"`. Empty or `0` hides it |
| `badgeColor` | Color | This tab's badge background. Overrides the bar's `badgeColor` |

### TabBarScreen Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `tabs` | Tab[] | | Tab definitions |
| `initialTab` | string | First tab | Initial tab ID |
| `tintColor` | Color | System blue | Selected tab color |
| `unselectedColor` | Color | Gray | Unselected tab color |
| `badgeColor` | Color | System red | Badge background on every tab. iOS `UITabBarItem.badgeColor`; Android `Badge(containerColor)` |
| `badgeTextColor` | Color | White | Badge text color. iOS `setBadgeTextAttributes(_:for:)` (normal and selected); Android `Badge(contentColor)` |

### Reselecting the selected tab

Tapping the tab that is already selected follows each platform's convention:

1. When the tab has pushed screens, it pops back to its root screen (animated).
2. At the root, the screen's main vertical scroll view (the outermost visible `scrollView` or vertical `collection`) scrolls to its top rest position, animated: below the navigation bar and any large title, not to raw offset 0.

| Platform | Reselect |
|----------|----------|
| iOS | `UITabBarControllerDelegate.tabBarController(_:shouldSelect:)` on the selected tab: `popToRootViewController(animated:)`, else `setContentOffset(-adjustedContentInset.top, animated: true)` |
| Android | Navigation bar item tapped while selected: pop the tab's back stack to its root, else `animateScrollToItem(0)` / `animateScrollTo(0)` on the screen's main list |
| Web | Same as Android: pop to root, else smooth `scrollTo({ top: 0 })` on the screen's main scroller |

### Programmatic Tab Selection

```json
{
  "type": "selectTab",
  "tabId": "profile"
}
```

Or by index:

```json
{
  "type": "selectTab",
  "tabIndex": 2
}
```

---

## Dismissing Modals

Close modal screens (sheet, fullScreen, formSheet, pageSheet).

```json
{
  "type": "dismiss"
}
```

A `navigation` that follows `dismiss` in the same action list waits until the modal
is gone and then runs from the presenting screen's navigation stack. See
[Dismiss, then navigate](actions.md#dismiss-then-navigate).

---

## Going Back

Pop the current screen (back one) with `isBack`, or pop all the way to the
navigation-stack root ("back to list") by adding `toRoot`:

```json
{ "type": "navigation", "isBack": true }
```

```json
{ "type": "navigation", "isBack": true, "toRoot": true }
```

---

## Disabling swipe-back

By default a pushed screen can be popped with the iOS interactive **swipe-back**
edge gesture. Set `swipeBackEnabled: false` on the screen's `content` to turn that
gesture off while the screen is on top — useful for forward-only flows
(onboarding, a wizard, a checkout step) where an accidental back-swipe would lose
state or skip a required action.

```json
{
  "type": "screen",
  "id": "onboarding-goals",
  "content": {
    "navigationBar": { "hidden": true },
    "swipeBackEnabled": false,
    "children": [ ]
  }
}
```

The flag is per-screen and applies whenever that screen is the visible (top)
one. It disables **both** the system swipe-back and any custom interactive-pop
edge-pan (see [transitions.md](transitions.md#interactive-dismiss--pop)), so the
screen can only be left programmatically (a button running
`{ "type": "navigation", "isBack": true }`, `completeFlow`, etc.). It does not
affect the push/pop **animation** — pair it with any `transition`. A back button
in the `navigationBar` still works; only the gesture is suppressed.

---

## Complete Example

### App with Onboarding and Tabs

```json
{
  "app": {
    "name": "MyApp",
    "variables": {
      "isOnboarded": { "type": "boolean", "initialValue": false }
    }
  },
  "navigation": {
    "startFlow": "onboarding",
    "flows": [
      { "id": "onboarding", "startScreen": "welcome" },
      { "id": "main", "startScreen": "tabBar" }
    ]
  },
  "screens": {
    "welcome": {
      "type": "screen",
      "content": {
        "navigationBar": { "hidden": true },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "Welcome!" },
              "layout": { "centerX": 0, "top": 200 }
            }
          },
          {
            "type": "button",
            "content": {
              "properties": { "text": "Get Started" },
              "layout": { "centerX": 0, "top": 300, "width": 200, "height": 50 },
              "actions": {
                "tap": {
                  "type": "completeFlow",
                  "destination": "main"
                }
              }
            }
          }
        ]
      }
    },
    "tabBar": {
      "type": "tabBarScreen",
      "content": {
        "tabs": [
          { "id": "home", "label": "Home", "icon": "house.fill", "screen": "home" },
          { "id": "profile", "label": "Profile", "icon": "person.fill", "screen": "profile" }
        ],
        "initialTab": "home",
        "tintColor": "#007AFF"
      }
    },
    "home": {
      "type": "screen",
      "content": {
        "navigationBar": { "title": "Home" },
        "children": [
          {
            "type": "button",
            "content": {
              "properties": { "text": "View Details" },
              "layout": { "centerX": 0, "top": 100 },
              "actions": {
                "tap": {
                  "type": "navigation",
                  "nextScreen": "details",
                  "params": { "itemId": "123" }
                }
              }
            }
          }
        ]
      }
    },
    "details": {
      "type": "screen",
      "content": {
        "inputParameters": {
          "itemId": { "type": "string", "required": true }
        },
        "navigationBar": {
          "title": "Details",
          "rightAction": {
            "label": "Edit",
            "action": {
              "type": "navigation",
              "nextScreen": "edit",
              "presentation": "sheet"
            }
          }
        },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "Item: {{itemId}}" },
              "layout": { "leading": 20, "top": 20 }
            }
          }
        ]
      }
    },
    "edit": {
      "type": "screen",
      "content": {
        "navigationBar": {
          "title": "Edit",
          "leftAction": {
            "label": "Cancel",
            "action": { "type": "dismiss" }
          },
          "rightAction": {
            "label": "Save",
            "style": "bold",
            "action": [
              { "type": "executeFunction", "function": "save" },
              { "type": "dismiss" }
            ]
          }
        }
      }
    },
    "profile": {
      "type": "screen",
      "content": {
        "navigationBar": { "title": "Profile" },
        "children": [ ]
      }
    }
  }
}
```
