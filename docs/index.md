# App8 DSL Reference

App8 DSL is a JSON-based declarative UI definition language that renders to native components: UIKit on iOS, Jetpack Compose on Android (see [platforms](platforms.md)). It supports reactive variables, state management, and flow-based navigation.

## Document Conventions

- `[Planned]` - Feature designed but not yet implemented
- `[Partial]` - Feature partially implemented
- JSON examples use standard JSON syntax

## Unknown and mistyped values

Unknown or mistyped values are ignored, never fatal. An engine renders every
part of a document it understands and skips the rest; it never rejects a
screen, an app or a template, and never crashes, because one value is wrong
or newer than the engine.

| Input | What the engine does |
|---|---|
| A property the engine does not know (newer DSL, typo) | Ignored |
| A value of the wrong type (`"title": 5`, `"hidesTabBar": "no"`, an object where a number goes) | Ignored: the property takes its default, as if it were absent. Its siblings, its component and the screen stay |
| An unknown enum value (`"alignment": "diagonal"`) | The property's default, unless its own docs name a fallback |
| An unknown component `type` (not a template name either) | That component is skipped; its siblings render |
| An unknown action `type` | That action is skipped; the rest of the list runs (see [actions](actions.md#unknown-action-types)) |
| A template name that does not exist (`template`, section templates, `templates[key]`) | The component or item is skipped |
| A number out of range (a huge size or index, a negative inset, `NaN` from an expression) | Clamped to the nearest usable value, or ignored |
| An expression that does not parse or evaluate | The property keeps its raw text (texts) or its default (other properties) |

Each ignored value logs one warning naming its JSON path (iOS and Android: the
engine's diagnostics, code `value.ignored` for decoding; web renderer: the
console, `[app8] <code>: …`). Coercions the DSL defines stay in force: the
[boolean coercion](variables.md#boolean-coercion), and numbers written as
numeric strings where a property's docs allow them. A document fails to load
only when its root is unusable: not an object, or no `type`.

The same rules hold inside a value decoded on its own: a bottom bar's component
and a context menu's preview component (since 0.7.17; before, one mistyped value
there failed the screen on iOS and dropped the whole bar on Android, with no
message in a release build). A screen that still cannot be decoded (its root is
unusable) does not open: the engine logs it at error level with the screen id and
the JSON path, in release builds too (iOS: the system log, subsystem
`dev.app8.engine`; Android: logcat tag `App8`, code `screen.load.failed`).

Authoring tools show what was ignored: an editor preview outlines a component
that failed to render and names the warning. Share pages and apps render
nothing for it. On iOS, `App8.showErrors` (on in debug builds, off in release
builds) draws such a component as a red box instead; preview hosts may turn
it on.

## Quick Start

A minimal app with one screen and a button:

```json
{
  "app": {
    "name": "MyApp"
  },
  "navigation": {
    "startFlow": "main",
    "flows": [
      { "id": "main", "startScreen": "home" }
    ]
  },
  "screens": {
    "home": {
      "type": "screen",
      "content": {
        "navigationBar": { "title": "Home" },
        "variables": {
          "count": { "type": "number", "initialValue": 0 }
        },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "Count: {{count}}" },
              "style": { "text": { "id": "countLabel", "type": "text", "content": { "fontSize": 24, "alignment": "center" } } },
              "layout": { "leading": 20, "trailing": 20, "top": 100 }
            }
          },
          {
            "type": "button",
            "content": {
              "properties": { "text": "Increment" },
              "layout": { "centerX": 0, "top": 160, "width": 200, "height": 50 },
              "actions": {
                "tap": {
                  "type": "incrementVariable",
                  "variableName": "count",
                  "by": 1
                }
              }
            }
          }
        ]
      }
    }
  }
}
```

## App Structure

```json
{
  "app": {
    "name": "AppName",
    "variables": { }
  },
  "navigation": {
    "startFlow": "flowId",
    "flows": [ ]
  },
  "screens": { },
  "templates": [ ]
}
```

| Key | Description |
|-----|-------------|
| `app` | App metadata and global variables; `minEngineVersion`, the oldest engine release that renders the app ([host-integration.md](host-integration.md#minimum-engine-version)) |
| `navigation` | Flow definitions and start flow |
| `screens` | Screen definitions by ID |
| `templates` | Reusable component templates |
| `prefabs` | Feature packages expanded into screens at bundle build time ([prefabs.md](prefabs.md)) |

## Component Types

**Layout & containers**

| Type | Description | See |
|------|-------------|-----|
| `screen` | Top-level screen container | [components/screen.md](components/screen.md) |
| `view` | General-purpose container | [components/view.md](components/view.md) |
| `stackView` | Linear layout container | [components/stack-view.md](components/stack-view.md) |
| `scrollView` | Scrollable container | [components/scroll-view.md](components/scroll-view.md) |
| `tabBarScreen` | Tab-based navigation | [components/tab-bar-screen.md](components/tab-bar-screen.md) |

**Content & display**

| Type | Description | See |
|------|-------------|-----|
| `label` | Text display | [components/label.md](components/label.md) |
| `button` | Interactive button | [components/button.md](components/button.md) |
| `image` | Image display | [components/image.md](components/image.md) |
| `icon` | SF Symbol, asset, or remote icon | [components/icon.md](components/icon.md) |
| `map` | Interactive map with annotations and routing | [components/map.md](components/map.md) |
| `shape` | Arc rings, bars, circles, dividers | [components/shape.md](components/shape.md) |

**Host-provided**

| Type | Description | See |
|------|-------------|-----|
| `native` | A view the host app registers (signature pad, video call, …), with props, events and a DSL fallback | [components/native.md](components/native.md) |

**Lists**

| Type | Description | See |
|------|-------------|-----|
| `collection` | Data-driven lists, grids, carousels | [collections.md](collections.md) |
| `tableView` | Static grouped/settings lists | [components/table-view.md](components/table-view.md) |

**Inputs** — see [forms.md](forms.md) for putting these together

| Type | Description | See |
|------|-------------|-----|
| `textField` | Single-line text input | [components/text-field.md](components/text-field.md) |
| `textView` | Multi-line text input | [components/text-view.md](components/text-view.md) |
| `toggle` | On/off switch | [components/toggle.md](components/toggle.md) |
| `slider` | Numeric slider | [components/slider.md](components/slider.md) |
| `picker` | Single-choice menu / segmented control | [components/picker.md](components/picker.md) |
| `datePicker` | Date / time selector | [components/date-picker.md](components/date-picker.md) |

**Feedback & loading**

| Type | Description | See |
|------|-------------|-----|
| `activityIndicator` | Spinner for indeterminate waits | [components/activity-indicator.md](components/activity-indicator.md) |
| `shimmer` | Skeleton loading placeholder | [components/shimmer.md](components/shimmer.md) |
| `pageControl` | Page-indicator dots | [components/page-control.md](components/page-control.md) |

## Style Types

| Type | Purpose | See |
|------|---------|-----|
| `color` | Hex color with theme support | [styles.md](styles.md#color) |
| `fill` | Solid or gradient background | [styles.md](styles.md#fill) |
| `material` | Composition of visual layers | [styles.md](styles.md#material) |
| `outline` | Border/stroke styling | [styles.md](styles.md#outline) |
| `shadow` | Drop shadow | [styles.md](styles.md#shadow) |
| `corner` | Corner radius | [styles.md](styles.md#corner) |
| `visualEffect` | Blur effects | [styles.md](styles.md#visualeffect) |
| `text` | Typography styling | [styles.md](styles.md#text-textmodel) |
| `transform` | View transformations | [styles.md](styles.md#transform) |

## Action Types

| Type | Purpose | See |
|------|---------|-----|
| `navigation` | Navigate to screen | [actions.md](actions.md#navigation-actions) |
| `dismiss` | Close modal | [actions.md](actions.md#dismiss-modal) |
| `completeFlow` | Finish flow, go to destination | [actions.md](actions.md#complete-flow) |
| `selectTab` | Switch tab | [actions.md](actions.md#select-tab) |
| `updateVariable` | Set variable value | [actions.md](actions.md#variable-actions) |
| `incrementVariable` | Add to number | [actions.md](actions.md#increment-number) |
| `toggleArrayValue` | Add/remove from array | [actions.md](actions.md#toggle-array-value) |
| `appendToArray` | Append to array | [actions.md](actions.md#append-to-array) |
| `updateMultipleVariables` | Batch update variables | [actions.md](actions.md#update-multiple-variables) |
| `resetVariables` | Reset to initial values | [actions.md](actions.md#reset-variables) |
| `executeFunction` | Call backend function | [actions.md](actions.md#function-actions) |
| `setState` | Change component state | [actions.md](actions.md#state-actions) |
| `focus` | Focus component | [actions.md](actions.md#focus-actions) |
| `focusNext` | Focus next focusable | [actions.md](actions.md#focus-actions) |
| `focusPrevious` | Focus previous focusable | [actions.md](actions.md#focus-actions) |
| `dismissKeyboard` | Close keyboard | [actions.md](actions.md#focus-actions) |
| `showAlert` | Present a native alert | [actions.md](actions.md#show-alert) |
| `haptic` | Trigger haptic feedback | [actions.md](actions.md#haptic) |
| `openURL` | Open a URL | [actions.md](actions.md#open-url) |
| `capturePhoto` | Take or pick a photo and store it on the device | [photos.md](photos.md#capturephoto) |
| `deletePhoto` | Remove a stored photo | [photos.md](photos.md#deletephoto) |
| `emit` | Fire typed event to the host event bus | [events.md](events.md) |

## Expression Syntax

Expressions use `{{...}}` syntax:

```json
"text": "{{userName}}"
"text": "{{user.profile.name}}"
"text": "{{items[0].title}}"
"value": "{{count + 1}}"
"hidden": "{{!isVisible}}"
"icon": "{{isLiked ? 'heart.fill' : 'heart'}}"
```

See [variables.md](variables.md) for full expression documentation.

## Documentation Index

**Core reference**

- [components.md](components.md) - All component types and properties
- [styles.md](styles.md) - Style system (colors, materials, text, content modes, etc.)
- [layout.md](layout.md) - Layout and constraint system
- [variables.md](variables.md) - Variables and expression syntax
- [actions.md](actions.md) - Actions and event triggers
- [photos.md](photos.md) - Capture, store and show photos on the device
- [gestures.md](gestures.md) - Continuous gesture → variable bindings (`pan`), and composing custom controls
- [context-menu.md](context-menu.md) - Long-press preview and actions (iOS context menu, Android quick-view sheet)
- [navigation.md](navigation.md) - Navigation and flow system
- [transitions.md](transitions.md) - Screen transitions (presets, custom keyframes, registry, interactive), sized modal popups / sheets, and shared-element / hero / composite morphs

**Building interfaces**

- [forms.md](forms.md) - Inputs, two-way binding, validation, and loading states
- [collections.md](collections.md) - Lists, grids, and carousels
- [collections-best-practices.md](collections-best-practices.md) - Layout choice, insets, headers, templates, and common mistakes
- [states.md](states.md) - Component states and animations
- [animations.md](animations.md) - Animation primitive (timing, springs, registry, per-property)
- [templates.md](templates.md) - Reusable component templates
- [prefabs.md](prefabs.md) - Feature packages (screens, templates, params) instantiated per app and expanded at bundle build time
- [localization.md](localization.md) - Translations, the `$i18n` marker, locale fallback

**Host & analytics**

- [host-integration.md](host-integration.md) - Data sources, datasources, assets, streaming, event wiring, and native components
- [components/native.md](components/native.md) - Host-registered native views: props, events, fallback
- [events.md](events.md) - Host-facing event bus (`.emit` action + subscribe API)
- [analytics.md](analytics.md) - Analytics bus (auto `app8.*` + author-declared `analytics` binding, SDK auto-prefixed)
- [analytics-events.spec.md](analytics-events.spec.md) - Canonical registry of every auto-fired event (cross-platform contract)
