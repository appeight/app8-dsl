# Components

Components are the building blocks of App8 DSL interfaces.

## Component Structure

Every component shares the same envelope:

<!-- @dsl-skip: generic structure example -->
```json
{
  "type": "componentType",
  "id": "optionalId",
  "templateId": "optionalTemplateRef",
  "content": { }
}
```

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | string | Yes | Component type |
| `id` | string | No | Unique identifier for references |
| `templateId` | string | No | Template to inherit from ([templates.md](templates.md)) |
| `defer` | object | No | Build this component after the screen is shown ([Deferred sections](#deferred-sections)) |
| `content` | object | Yes | Type-specific content |

`content` is where each component differs, but most components accept these shared keys:

| Key | Description | See |
|-----|-------------|-----|
| `properties` | Type-specific values (text, url, data, …) | Per-component doc below |
| `style` | Visual styling | [styles.md](styles.md) |
| `layout` | Position and size constraints | [layout.md](layout.md) |
| `actions` | Event handlers | [actions.md](actions.md) |
| `gestures` | Continuous gesture → variable bindings | [gestures.md](gestures.md) |
| `contextMenu` | Long-press preview and actions (view, stackView, image, button) | [context-menu.md](context-menu.md) |
| `interaction` | Touch / clipping / z-order overrides | [Interaction](#interaction) below |
| `accessibility` | VoiceOver metadata | [Accessibility](#accessibility) below |
| `variables` | Component-scoped variables | [variables.md](variables.md) |
| `states` / `triggers` | State machine | [states.md](states.md) |
| `children` | Nested components (containers only) | — |

---

## Visibility

`properties.isHidden` hides **any** component: view, label, icon, button, image,
collection, stackView, scrollView, native, inputs and the rest. It takes a boolean
or a `{{expression}}` (read with the [boolean coercion](variables.md#boolean-coercion))
and re-evaluates when a variable it reads changes.

<!-- @dsl-type: Component -->
```json
{
  "type": "button",
  "content": {
    "properties": {
      "text": "Remove",
      "isHidden": "{{selectedIds.length == 0}}"
    }
  }
}
```

A hidden component is not drawn, does not receive touches, and is skipped by
accessibility. Inside a [`stackView`](components/stack-view.md) it also takes no
space: the stack lays out as if it were not there, spacing included (as
`UIStackView` does with hidden arranged subviews). Outside a stack it keeps its
frame, so constraints that point at it still resolve. Its children are hidden
with it.

`isHidden` also takes the wrapped form `{ "value": …, "animation": … }`: a
change then animates instead of applying at once. In a stack the component
grows or shrinks along the stack axis while it fades and everything after it
moves along (a disclosure row opening); elsewhere it cross-fades. See
[Animated visibility](animations.md#animated-visibility).

---

## Deferred sections

A screen is built before it is shown. A long screen (a product page with
details, ingredients, FAQs and reviews) takes time to build, and a navigation
transition cannot start until the screen exists. `defer` lets the part the user
sees first appear at once and the rest follow.

A component with `defer` is not built with its screen. A placeholder takes its
place, and the engine builds the component once the screen is on screen (the
push or zoom transition has already started), then swaps it in with a short
fade (0.2 s, cubic ease-out).

<!-- @dsl-type: Component -->
```json
{
  "type": "stackView",
  "id": "productStack",
  "content": {
    "properties": { "axis": "vertical", "spacing": 24 },
    "children": [
      { "type": "label", "id": "title", "content": { "properties": { "text": "{{product.title}}" } } },
      {
        "type": "view",
        "id": "details",
        "defer": { "placeholder": "shimmer", "estimatedHeight": 240 },
        "content": { "children": [] }
      },
      {
        "type": "view",
        "id": "faqs",
        "defer": { "placeholder": "none" },
        "content": { "children": [] }
      }
    ]
  }
}
```

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `placeholder` | `"shimmer"` \| `"none"` | `"none"` | `shimmer`: a neutral rounded block with a sweeping highlight, as wide as the stack. `none`: empty space. |
| `estimatedHeight` | number | `0` | Placeholder height in a vertical stack. Use the section's usual height so the content below moves as little as possible when it arrives. |
| `estimatedWidth` | number | `0` | Placeholder width in a horizontal stack. |

Rules:

- `defer` works on the direct children of a [`stackView`](components/stack-view.md).
  Anywhere else the component is built with its screen (warning
  `defer.notInStack`).
- Deferred components are built in document order, a few per frame, so the
  transition stays smooth. Each one is built only while its screen is in the
  window.
- Until it is built, a deferred component does not exist: actions and
  constraints that name its `id` find nothing, and its variables are not
  defined. Keep screen state in screen or app variables, not in a deferred
  component.
- A deferred component whose `isHidden` is true when its screen is built
  gets no placeholder space (`isHidden` is read in the stack's scope, since
  the component's own variables don't exist yet).
- `defer` inside a deferred component, and inside collection items and
  templates rendered per item, is ignored without a warning: those are built
  with their parent.
- `defer` must be an object; any other value is ignored. An unknown
  `placeholder` means `none`; negative estimates mean `0`.
- Put the content needed for the first frame (the image a zoom transition
  grows from, the title) outside deferred components.
- Engines that predate `defer` ignore it and build everything with the screen.

---

## Interaction

The optional `content.interaction` block overrides touch handling, clipping, and
z-ordering on **any** component. All fields accept a literal (`"true"`, `"2"`) or a
`{{expression}}` and re-evaluate reactively when variables change.

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | [boolean](variables.md#boolean-coercion)/expression | Explicit `isUserInteractionEnabled`. By default a component only handles touches when it declares `actions` / `triggers` / `gestures`; set this to force-enable a passive container or force-disable an otherwise-interactive subtree. |
| `clipsToBounds` | [boolean](variables.md#boolean-coercion)/expression | Clip children to the component's bounds. |
| `zIndex` | number/expression | Raise/lower the component among its siblings (maps to `layer.zPosition`) without reordering the hierarchy. |

```json
{
  "type": "view",
  "content": {
    "interaction": { "enabled": "{{editing}}", "clipsToBounds": "true", "zIndex": "10" }
  }
}
```

## Accessibility

The optional `content.accessibility` block sets VoiceOver metadata on any component.
String fields accept a literal or `{{expression}}`. (`accessibilityIdentifier` is set
automatically from the component `id`.)

| Field | Type | Description |
|-------|------|-------------|
| `label` | string/expression | Spoken label. |
| `hint` | string/expression | Spoken hint. |
| `value` | string/expression | Spoken value (e.g. a slider's current value). |
| `traits` | string[] | Accessibility traits — e.g. `["button", "header"]`. See values below. |
| `isElement` | [boolean](variables.md#boolean-coercion)/expression | Override `isAccessibilityElement`. |
| `hidden` | [boolean](variables.md#boolean-coercion)/expression | Hide from accessibility (`accessibilityElementsHidden`). |

Trait values: `button`, `link`, `header`, `image`, `selected`, `disabled`,
`adjustable`, `searchField`, `staticText`, `summaryElement`, `updatesFrequently`,
`startsMediaSession`, `allowsDirectInteraction`.

```json
{
  "type": "image",
  "content": {
    "accessibility": { "label": "Profile photo", "hint": "Double tap to change", "traits": ["button"] }
  }
}
```

---

## Component Reference

Each component type has its own reference doc with its `properties`, styling, and examples.

| Type | Description | Docs |
|------|-------------|------|
| `screen` | Top-level screen container | [components/screen.md](components/screen.md) |
| `view` | General-purpose container | [components/view.md](components/view.md) |
| `label` | Text display | [components/label.md](components/label.md) |
| `button` | Interactive button | [components/button.md](components/button.md) |
| `image` | Image display | [components/image.md](components/image.md) |
| `video` | Looping background video (local asset) | [components/video.md](components/video.md) |
| `icon` | SF Symbol, asset, or remote icon | [components/icon.md](components/icon.md) |
| `textField` | Single-line text input | [components/text-field.md](components/text-field.md) |
| `textView` | Multi-line text input | [components/text-view.md](components/text-view.md) |
| `toggle` | On/off switch | [components/toggle.md](components/toggle.md) |
| `slider` | Numeric slider | [components/slider.md](components/slider.md) |
| `picker` | Single-choice menu / segmented control | [components/picker.md](components/picker.md) |
| `datePicker` | Date / time selector | [components/date-picker.md](components/date-picker.md) |
| `scrollView` | Scrollable container | [components/scroll-view.md](components/scroll-view.md) |
| `stackView` | Linear layout container | [components/stack-view.md](components/stack-view.md) |
| `tabBarScreen` | Tab-based navigation | [components/tab-bar-screen.md](components/tab-bar-screen.md) |
| `collection` | Data-driven lists, grids, carousels | [collections.md](collections.md) |
| `tableView` | Static grouped/settings lists | [components/table-view.md](components/table-view.md) |
| `map` | Interactive map with annotations and routing | [components/map.md](components/map.md) |
| `shape` | Arc rings, bars, circles, dividers | [components/shape.md](components/shape.md) |
| `activityIndicator` | Spinner for indeterminate waits | [components/activity-indicator.md](components/activity-indicator.md) |
| `shimmer` | Skeleton loading placeholder | [components/shimmer.md](components/shimmer.md) |
| `pageControl` | Page-indicator dots | [components/page-control.md](components/page-control.md) |
| `native` | Host-registered native view with props, events and a DSL fallback | [components/native.md](components/native.md) |

These cover the building blocks; [forms.md](forms.md) shows how to combine the input components, and [host-integration.md](host-integration.md) covers how the host feeds them data.
