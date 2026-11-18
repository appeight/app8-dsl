# Native

Embeds a view that the **host app** provides (a signature pad, a video call, a payment sheet, anything the DSL cannot draw) in a DSL screen. The DSL names a **module**, passes it **props**, and reacts to the **events** the module emits with ordinary actions. Everything around the native view (layout, navigation, the screens before and after) stays DSL and can change over the air.

A screen that uses a module the host has not registered still renders: it shows the component's **fallback** subtree instead.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.module` | string | required | Name the host registered the module under, e.g. `"signaturePad"` |
| `properties.props` | object | `{}` | Values handed to the host view. String values (at any depth) accept `{{expr}}`; see [Props](#props) |
| `actions` | object | none | Actions keyed by **event name** emitted by the module, plus the engine's `appear` and `disappear`; see [Events](#events) and [Visibility](#visibility) |
| `analytics` | object | none | Analytics bindings keyed by **event name**; see [Analytics](#analytics) |
| `fallback` | Component | none | Any DSL subtree, rendered in place of the native view when no host module is registered for `module` |
| `layout` | Layout | | Normal [layout](../layout.md); the native view (or the fallback) fills the component's frame |
| `style` | View style | | Same as [`view`](view.md) (background, corners, …), drawn behind the native view |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | | Hide component; see [Visibility](../components.md#visibility) |

`native` has no `children`; use `fallback` for DSL content.

## Props

`props` is a free-form JSON object. The engine resolves it before handing it to the host:

- String values containing `{{…}}` are evaluated against the component's scope. A whole-string expression keeps its type (`"{{colors}}"` passes the array), mixed text interpolates (`"Signed by {{name}}"`).
- Numbers, booleans, `null`, arrays and nested objects pass through; strings inside them resolve the same way.
- When a variable that the props read changes, the engine re-resolves them and gives the host the new object (iOS `onPropsChange`, Android recomposition, web re-render). The native view is not rebuilt.

## Events

The module emits named events with a JSON payload (`completed { signature }`, `cancelled {}`, …). Each event does two things:

1. **Runs `actions[eventName]`**, if declared, in JSON order. While those actions run, the payload is in scope as `event`: `{{event.signature.id}}`, `{{event.reason}}`. This is the same mechanism that exposes `item` to a map's `onAnnotationTap`. Variable actions write to the real variables; navigation `params`, `emit` payloads and `openURL` urls read `event`. Each value may be a single action or an array.
2. **Is forwarded to the host event bus** as `native.<module>.<event>` (for example `native.signaturePad.completed`) with the payload unchanged, `componentId` set to the component's `id` and `componentType` `"native"`. Hosts observe it with the usual [subscribe API](../events.md); no DSL needed.

Events without a matching key in `actions` are still forwarded to the bus. Event names are the module's contract; document them next to the module.

`appear` and `disappear` are reserved for the engine's [visibility events](#visibility). A module that emits either name is ignored for that call, with a `native.event.reserved` warning.

## Analytics

`analytics` takes the same keys as `actions`, the module's event names, with the
usual [analytics binding](../analytics.md#author-declared-analytics) forms (a
string event name, or `name` + `properties`). When the module emits an event that
has a binding, the engine dispatches the analytics event on the analytics bus, with
the payload in scope as `event` while `properties` resolve. A binding fires whether
or not `actions` has a key for that event.

<!-- @dsl-type: Component -->
```json
{
  "id": "signature",
  "type": "native",
  "content": {
    "properties": { "module": "signaturePad" },
    "actions": {
      "completed": { "type": "navigation", "nextScreen": "confirm" }
    },
    "analytics": {
      "completed": { "name": "signatureCompleted", "properties": { "stroke_count": "{{event.strokeCount}}" } },
      "cancelled": "signatureCancelled"
    }
  }
}
```

The dispatched event carries `component_id` (the component's `id`) and
`component_type` `"native"` like any other binding. The binding, the actions and
the `native.<module>.<event>` bus post are independent; do not rely on their order.
There is no auto `app8.component.tapped` event for native components: the module
decides what its events mean.

## Visibility

A module that runs something while it is on screen (a camera, a video player, a sensor, a timer) needs to know when the user can actually see it. The engine tracks that for every `native` component and tells the host view and the DSL.

### When a component is visible

A `native` component is **visible** when all of these hold:

1. Its screen is the **topmost presented screen of the selected tab**: not covered by a modal presentation (any `sheet` detent, `fullScreen`, `formSheet`, `pageSheet`, a custom modal or popup), not in a tab that is not selected, and not a screen lower in a navigation stack.
2. The app is in the **foreground**.
3. The component is **in the window** (iOS) or **in the composition** (Android) and is not hidden: neither it nor an ancestor has `isHidden` true.
4. It is **not an offscreen render**: snapshot windows, measuring passes, prebuilt tab roots that have not been shown, and collection cells that are not on screen (prefetched, recycled, scrolled out of the list) are never visible.

Everything else is still visible. In particular:

- A component inside a `scrollView` that is scrolled out of the viewport stays visible. Only collection (list) cells track their own on-screen state.
- System alerts (`showAlert`) and context-menu previews do not change visibility.
- An inactive app (Control Center, the app switcher, an incoming-call banner) is still in the foreground. Visibility changes only when the app enters the background (iOS scene `didEnterBackground` / `willEnterForeground`, Android lifecycle `ON_STOP` / `ON_START`, web `document.visibilityState`).
- The fallback counts: when the component shows its `fallback` instead of a module view, it still has a visibility and still runs `appear` / `disappear`.

### When changes are delivered

- Every component starts not visible. In the factory (iOS) or on first composition (Android, web) `isVisible` is `false`.
- Changes are delivered on the main thread and only when the value changes, never twice in a row with the same value.
- Transitions are debounced to their ends: `true` arrives **after** the appear transition completes, `false` arrives **when** a disappear transition starts. Pushing over a screen, presenting a modal over it, popping or dismissing it all report `false` at the start of the animation.
- An interactive transition that is cancelled (a swipe-back released early, a sheet dragged and let go) reports `false` when it starts and `true` again once the cancelled animation settles. The screen underneath stays `false` unless the transition completes.
- A tab switch reports `false` for the old tab's components and `true` for the new tab's once the switch completes.
- `isHidden` changes, foreground and background changes apply at once (there is no transition to wait for).
- When a visible component is removed (its screen is popped or dismissed, its cell is recycled, the screen re-renders), `false` is delivered before the view is torn down.

The engine derives visibility from the screen lifecycle (iOS view controller appearance, tab selection, presentation, window and scene state; Android back stack entries, presented modals and lifecycle), never from view creation. Screens are often built before they are shown: tab roots, snapshot renders, reused cells, scroll views that build their children twice. On Android the screen under a sheet or modal stays composed and is still not visible.

### In the DSL: `appear` and `disappear`

`actions` may contain `appear` and `disappear`. The engine runs them when the component becomes visible and when it stops being visible, with an empty payload (`event` is `{}`). They follow the same rules as module events: a single action or an array, run in JSON order, and `analytics` bindings may use the same keys. Unlike module events they are **not** posted on the event bus; the host already gets them through the context.

<!-- @dsl-type: Component -->
```json
{
  "id": "player",
  "type": "native",
  "content": {
    "properties": { "module": "videoPlayer", "props": { "url": "{{clip.url}}" } },
    "layout": { "leading": 0, "trailing": 0, "top": 0, "height": 220 },
    "actions": {
      "appear": { "type": "incrementVariable", "variableName": "playerAppearCount", "by": 1 },
      "disappear": { "type": "updateVariable", "variableName": "lastPausedClip", "value": "{{clip.id}}" }
    },
    "analytics": {
      "appear": "playerShown"
    }
  }
}
```

The host view and the DSL each get the change; the order between the host callback (or recomposition) and the DSL actions is not specified.

### In the host

| Platform | Read | Observe |
|----------|------|---------|
| iOS | `context.isVisible: Bool` (`public private(set) var`) | `context.onVisibilityChange: ((Bool) -> Void)?`, called on the main actor for each change after you set it (not with the current value) |
| Android | `context.isVisible: Boolean` | A new `App8NativeContext` on each change, so the composable recomposes; key a `LaunchedEffect` on it |
| Web | `visible: boolean` in `NativeComponentProps` | Re-render with the new value; `live` is a deprecated alias with the same value |

## Fallback

`fallback` is any component (usually a `view` with a short message and a button). It is rendered, with its normal layout inside the native component's frame, when the host has no module registered under `module` at render time.

With no fallback and no registered module, the component renders as an empty view and the SDK logs a `native.module.missing` warning. It never shows an error view, so a bundle that names a module one platform has not shipped yet stays usable there.

## Example

A signature pad that stores the result and moves on:

<!-- @dsl-type: Component -->
```json
{
  "id": "signature",
  "type": "native",
  "content": {
    "properties": {
      "module": "signaturePad",
      "props": {
        "strokeColor": "#1A1A1A",
        "lineWidth": 3,
        "placeholder": "Sign here, {{userName}}"
      }
    },
    "layout": { "leading": 16, "trailing": 16, "top": 120, "height": 240 },
    "actions": {
      "completed": [
        { "type": "updateVariable", "variableName": "signatureUrl", "value": "{{event.signature.imageUrl}}" },
        { "type": "navigation", "nextScreen": "confirm", "params": { "signatureId": "{{event.signature.id}}" } }
      ],
      "cancelled": { "type": "dismiss" },
      "failed": [
        { "type": "updateVariable", "variableName": "signatureError", "value": "{{event.reason}}" }
      ]
    },
    "fallback": {
      "id": "signatureFallback",
      "type": "view",
      "content": {
        "layout": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 },
        "children": [
          {
            "id": "fallbackText",
            "type": "label",
            "content": {
              "properties": { "text": "Signing is not available on this device." },
              "layout": { "leading": 24, "trailing": 24, "centerY": 0 }
            }
          }
        ]
      }
    }
  }
}
```

## Host registration

Register the module once, before the first screen that uses it renders. One registration serves every `native` component with that `module`.

### iOS

```swift
import App8Engine

App8.registerNativeComponent("signaturePad") { context in
    // context.props    [String: Any], resolved
    // context.appId    app.id of the running app, if set
    // context.screenId screen the component renders in
    let view = SignaturePadView(strokeColor: context.props["strokeColor"] as? String)
    context.onPropsChange = { props in view.apply(props) }
    view.onDone = { signature in context.emit("completed", ["signature": signature]) }
    view.onClose = { context.emit("cancelled", [:]) }
    return view
}
```

`App8.registerNativeComponent(_ module: String, factory: @escaping @MainActor (App8NativeContext) -> UIView)` is process-wide. The returned view is pinned to the component's frame. `App8NativeContext` is main-actor bound: `props`, `onPropsChange`, `emit(_:_:)`, `module`, `appId`, `screenId`, `isVisible`, `onVisibilityChange` (see [Visibility](#visibility)).

A module that runs only while it is seen starts and stops on visibility:

```swift
App8.registerNativeComponent("videoPlayer") { context in
    let player = PlayerView(url: context.props["url"] as? String)
    context.onVisibilityChange = { visible in
        visible ? player.play() : player.pause()
    }
    return player
}
``` `App8.unregisterNativeComponent(_:)` removes a module; screens rendered afterwards show the fallback.

### Android

```kotlin
val config = App8Config(
    nativeComponents = mapOf(
        "signaturePad" to App8NativeComponent { context, modifier ->
            SignaturePad(
                strokeColor = context.props["strokeColor"] as? String,
                onDone = { signature -> context.emit("completed", mapOf("signature" to signature)) },
                modifier = modifier,
            )
        }
    )
)
```

`fun interface App8NativeComponent { @Composable fun Content(context: App8NativeContext, modifier: Modifier) }`. `App8NativeContext(props: Map<String, Any?>, emit: (String, Map<String, Any?>) -> Unit, appId, screenId, isVisible: Boolean = false)`. New props and visibility changes arrive as a new context (recomposition); apply `modifier` to the root so the component's layout applies.

```kotlin
"videoPlayer" to App8NativeComponent { context, modifier ->
    val player = rememberPlayer(context.props["url"] as? String)
    LaunchedEffect(context.isVisible) {
        if (context.isVisible) player.play() else player.pause()
    }
    PlayerSurface(player, modifier)
}
```

When the component leaves the composition, stop work in the composable's own `DisposableEffect` (or let the `LaunchedEffect` cancel); the DSL `disappear` actions still run.

### Web renderer

The web renderer takes a React component per module:

```tsx
registerNativeComponent("signaturePad", SignaturePad);

function SignaturePad({ props, emit, width, height, platform, visible }: NativeComponentProps) {
  // render inside width × height; platform is "ios" or "android" (the preview mode)
  // visible: see Visibility; start and stop work in an effect keyed on it
}
```

`NativeComponentProps = { props: Record<string, unknown>; emit(event: string, payload: Record<string, unknown>): void; width: number; height: number; platform: "ios" | "android"; appId?: string; visible: boolean; /** @deprecated use visible */ live: boolean }`.

## Notes

- `native` belongs to the 0.6.0 release. Older SDKs do not know the type; ship the screen only to apps on 0.6.0 or later.
- Visibility (`isVisible`, `onVisibilityChange`, web `visible`, the `appear` / `disappear` actions) belongs to 0.6.3. An older SDK ignores `appear` / `disappear` keys in `actions` (no module emits them).
- A module is code in the host app, so changing a module needs an app release. Keep everything that may change over the air (copy, the screens around it, what happens after each event) in the DSL.
- Data the module needs that should not live in the bundle (auth tokens, endpoints) belongs in the factory closure, not in props.
- Feature packages that need a module (see [prefabs](../prefabs.md)) list it under `requires.nativeModules`.
