# Native

Embeds a view that the **host app** provides (a signature pad, a video call, a payment sheet, anything the DSL cannot draw) in a DSL screen. The DSL names a **module**, passes it **props**, and reacts to the **events** the module emits with ordinary actions. Everything around the native view (layout, navigation, the screens before and after) stays DSL and can change over the air.

A screen that uses a module the host has not registered still renders: it shows the component's **fallback** subtree instead.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.module` | string | required | Name the host registered the module under, e.g. `"signaturePad"` |
| `properties.props` | object | `{}` | Values handed to the host view. String values (at any depth) accept `{{expr}}`; see [Props](#props) |
| `actions` | object | none | Actions keyed by **event name** emitted by the module; see [Events](#events) |
| `fallback` | Component | none | Any DSL subtree, rendered in place of the native view when no host module is registered for `module` |
| `layout` | Layout | | Normal [layout](../layout.md); the native view (or the fallback) fills the component's frame |
| `style` | View style | | Same as [`view`](view.md) (background, corners, …), drawn behind the native view |
| `hidden` | boolean/expression | | Hide component |

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
        "placeholder": "Sign here, {{customerName}}"
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

`App8.registerNativeComponent(_ module: String, factory: @escaping @MainActor (App8NativeContext) -> UIView)` is process-wide. The returned view is pinned to the component's frame. `App8NativeContext` is main-actor bound: `props`, `onPropsChange`, `emit(_:_:)`, `module`, `appId`, `screenId`. `App8.unregisterNativeComponent(_:)` removes a module; screens rendered afterwards show the fallback.

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

`fun interface App8NativeComponent { @Composable fun Content(context: App8NativeContext, modifier: Modifier) }`. `App8NativeContext(props: Map<String, Any?>, emit: (String, Map<String, Any?>) -> Unit, appId, screenId)`. New props arrive as a new context (recomposition); apply `modifier` to the root so the component's layout applies.

### Web renderer

The web renderer (Studio previews) takes a React component per module:

```tsx
registerNativeComponent("signaturePad", SignaturePad);

function SignaturePad({ props, emit, width, height, platform }: NativeComponentProps) {
  // render inside width × height; platform is "ios" or "android" (the preview mode)
}
```

`NativeComponentProps = { props: Record<string, unknown>; emit(event: string, payload: Record<string, unknown>): void; width: number; height: number; platform: "ios" | "android"; appId?: string }`.

## Notes

- `native` belongs to the 0.6.0 release. Older SDKs do not know the type; ship the screen only to apps on 0.6.0 or later.
- Author-declared `analytics` bindings are not supported on native events yet; observe `native.<module>.<event>` on the event bus instead.
- A module is code in the host app, so changing a module needs an app release. Keep everything that may change over the air (copy, the screens around it, what happens after each event) in the DSL.
- Data the module needs that should not live in the bundle (auth tokens, endpoints) belongs in the factory closure, not in props.
- Feature packages that need a module (see [prefabs](../prefabs.md)) list it under `requires.nativeModules`.
