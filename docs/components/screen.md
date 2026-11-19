# Screen

Top-level container for a screen.

## Content Properties

| Property | Type | Description |
|----------|------|-------------|
| `children` | Component[] | Child components |
| `variables` | object | Screen-scoped variables |
| `inputParameters` | object | Parameters passed from navigation |
| `navigationBar` | NavigationBar | Navigation bar configuration — see [Navigation Bar](#navigation-bar) below |
| `bottomBar` | BottomBar | Content pinned to the bottom of the screen above the safe area (usually primary buttons), with the platform's scroll-edge treatment — see [Bottom Bar](#bottom-bar) below |
| `onEvent` | EventTrigger[] | Screen lifecycle events — see [Event Triggers](#event-triggers) below |
| `style` | ScreenStyle | Screen styling |
| `additionalSafeAreaInsets` | EdgeInsets | Extra safe area insets applied to the screen — see [layout.md](../layout.md#additional-safe-area-insets-screen-level) |
| `hidesTabBar` | boolean | Hide the tab bar when this screen is pushed |
| `swipeBackEnabled` | boolean | Allow the interactive swipe-back (edge-pan pop) gesture while this screen is on top (default `true`). Set `false` for a forward-only screen — see [navigation.md — Disabling swipe-back](../navigation.md#disabling-swipe-back) |
| `dismissKeyboardOnTap` | boolean | Dismiss keyboard when tapping outside inputs (default `true`) |

## Navigation Bar

See [navigation.md — Navigation Bar](../navigation.md#navigation-bar) for full property reference.

| Property | Type | Description |
|----------|------|-------------|
| `title` | string / expression | Navigation bar title text; an expression updates when its variables change |
| `backLabel` | string | Custom back button label; none on the root of a stack |
| `hidden` | boolean | Hide the navigation bar |
| `leftAction` | BarAction | Leading bar button item |
| `rightAction` | BarAction | Trailing bar button item |
| `search` | SearchBar | System search field — see [navigation.md — Search](../navigation.md#search) |

**BarAction structure:**
```json
{
  "label": "Edit",
  "icon": "pencil",
  "action": { "type": "navigation", "nextScreen": "editProfile" }
}
```

## Bottom Bar

See [navigation.md — Bottom Bar](../navigation.md#bottom-bar) for layout, backgrounds and hiding.

| Property | Type | Description |
|----------|------|-------------|
| `component` | Component | The bar's content, usually a `stackView` of buttons (required) |
| `insets` | EdgeInsets | Space around `component`: `top` (default 12), `left` (16), `bottom` (8, above the bottom safe area), `right` (16) |
| `style.background` | `"system"` / style entity | `"system"` (default): iOS 26 scroll-edge effect, Android Material 3 surface; or a `material` / `fill` style entity |
| `edgeEffect` | string | iOS 26 scroll-edge effect for the system background: `soft` (default) or `hard` |
| `hidden` | [boolean](../variables.md#boolean-coercion)/expression | Hide the bar (animated, 0.33 s cubic ease-out) |

The bar's height is added to the screen's bottom safe area, so scroll content gets the matching bottom inset. Above a tab bar when one is shown.

## Event Triggers

See [actions.md — Event Triggers](../actions.md#event-triggers) for full reference.

| Event | Description |
|-------|-------------|
| `appear` | Screen has appeared (viewDidAppear) |
| `disappear` | Screen has disappeared (viewDidDisappear) |
| `timer` | Fires once after a `delay` (seconds) |

```json
"onEvent": [
  { "event": "appear", "action": { "type": "executeFunction", "function": "loadData" } },
  { "event": "timer", "delay": 1.5, "action": { "type": "updateVariable", "variableName": "isReady", "value": true } }
]
```

## Example

```json
{
  "type": "screen",
  "content": {
    "navigationBar": {
      "title": "Profile",
      "rightAction": {
        "label": "Edit",
        "action": { "type": "navigation", "nextScreen": "editProfile" }
      }
    },
    "variables": {
      "userName": { "type": "string", "initialValue": "" }
    },
    "inputParameters": {
      "userId": { "type": "string", "required": true }
    },
    "onEvent": [
      { "event": "appear", "action": { "type": "executeFunction", "function": "loadUser" } }
    ],
    "children": [ ]
  }
}
```
