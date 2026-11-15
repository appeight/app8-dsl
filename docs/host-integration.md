# Host Integration

The engine never fetches anything itself. The **host app** supplies all content through one protocol — `App8DataSource` — and receives runtime events through two buses. This page is the bridge between the DSL (what authors write) and the Swift host (what serves and reacts to it).

> New to the SDK? Start with the [README Quick Start](../../README.md#quick-start) for the bootstrap (`App8.instance(dataSource:)` → `startApp()`). This page details the data surfaces the DSL relies on.

---

## `App8DataSource`

Implement this protocol to feed the engine. Only the core reads are required; the rest have default implementations.

| Method | Returns | Purpose |
|--------|---------|---------|
| `getApp()` | `Data` | The app manifest (`app`, `navigation`, `screens`, `templates`) |
| `getStyles()` | `[Data]` | Shared style entities referenced by [style pointers](styles.md#style-pointers-advanced) |
| `getScreen(screenId:)` | `Data` | A single screen definition |
| `getComponent(componentId:)` | `Data` | A reusable component definition |
| `getComponents()` | `[Data]` | Preloaded shared components |
| `getDatasource(screenId:datasourceId:)` | `Data` | A [datasource](#datasources) file (e.g. `"datasources/listings"`) |
| `reloadDatasource(screenId:datasourceId:)` | `Data` | Optional — fresh bytes for the [`reloadDatasource`](actions.md#reloaddatasource) action, bypassing any cache. Default: `getDatasource` |
| `getAsset(assetId:assetName:)` | `Data?` | Raw bytes for an image/asset — see [Assets](#assets) |
| `getTranslations()` | `Data` | The i18n [translation bundle](localization.md#translation-bundle) |
| `getAllScreenIds()` | `[String]?` | Optional — enables orphan-screen diagnostics |
| `streamScreen(_:)` / `streamDatasource(...)` / `streamStyles()` | `AsyncStream<Data>?` | Optional — [live updates](#live-updates--streaming) |
| `prepareRequest(_:)` | `URLRequest` | Optional — authorize, route or reject [`request` actions](#http-requests-from-the-dsl). Default: unchanged |

Each method returns JSON `Data`. A bundle-backed implementation just reads files; a server-backed one makes network calls — the DSL is identical either way.

---

## Datasources

A **datasource** is an external JSON file of data that the DSL binds to without hardcoding it inline. An author points a variable at one with the `source` field; the engine calls `getDatasource(screenId:datasourceId:)` to load it.

**DSL side** — bind a variable to a datasource ([variables.md](variables.md#variable-definition)):

```json
"variables": {
  "listings": { "type": "array", "source": "datasources/listings" }
}
```

**Host side** — `getDatasource(screenId:, datasourceId: "datasources/listings")` returns the file. Two shapes are accepted:

```json
// Wrapped — schema is stored for tooling but not enforced at runtime
{ "schema": { }, "data": [ { "id": "1", "title": "Loft" } ] }
```

```json
// Raw — the array (or object) directly
[ { "id": "1", "title": "Loft" } ]
```

The `data` value populates the variable. Use [`schema`](variables.md#object-variables-with-schema) on the variable to document the expected shape for navigation params and tooling.

**App variables** may have a `source` too ([variables.md](variables.md#app-variables-with-a-source)). The engine loads them at app start with `getDatasource(screenId: "", datasourceId:)`: the empty `screenId` means "app scope".

**Reloading.** The [`reloadDatasource`](actions.md#reloaddatasource) action calls `reloadDatasource(screenId:datasourceId:)` (Android `reloadDatasource(screenId, datasourceId)`) for one `datasourceId`, with the id of the screen that runs it, and writes the result into every app and live-screen variable bound to that path. The default implementation calls `getDatasource`, which is right for a data source that always reads fresh data. A data source that caches (`getDatasource` serves a stored copy) implements `reloadDatasource` to bypass or refresh that cache, and throws when it cannot get fresh data so the action's `onError` runs instead of reporting stale data as reloaded. The App8 cloud SDKs do this: they refetch the screen response that carries the datasource.

---

## HTTP Requests from the DSL

The [`request`](actions.md#request) action sends HTTP requests itself, so the DSL can call an API (delete an item, save a note) without a host round trip. Every request first goes through the host's `prepareRequest` hook, the one place to add authorization, point requests at another host, or refuse them:

| Platform | Hook | Default |
|----------|------|---------|
| iOS | `App8DataSource.prepareRequest(_ request: URLRequest) async throws -> URLRequest` | Returns `request` unchanged |
| Android | `suspend fun App8DataSource.prepareRequest(request: App8HttpRequest): App8HttpRequest` | Returns `request` unchanged |
| Web | `AppRuntime.prepareRequest?: (req: Request) => Promise<Request>` | Not set: the request is sent unchanged |

```swift
func prepareRequest(_ request: URLRequest) async throws -> URLRequest {
    guard request.url?.host == "api.example.com" else { throw RequestNotAllowed() }
    var request = request
    request.setValue("Bearer \(try await session.accessToken())", forHTTPHeaderField: "Authorization")
    return request
}
```

The hook receives the request after the engine resolved the DSL (method, URL, headers, JSON body and `Content-Type`). Whatever it returns is sent. If it throws (Android: throws; web: the promise rejects), nothing is sent and the action's `onError` runs with `response.status` `0`.

Android's request type is a plain value: `data class App8HttpRequest(val method: String, val url: String, val headers: Map<String, String>, val body: String?)`, where `body` is the JSON text or `null`; return a modified `copy(...)`.

Keep tokens out of the bundle: the DSL names the endpoint, the host adds credentials here. A host that should not allow DSL requests at all rejects every request in the hook.

---

## Assets

`image` components resolve their bytes through the data source. When a screen references a remote image, the engine asks the host for it via `getAsset(assetId:assetName:)`. Returning `nil` lets the component fall back to its declared URL.

To **prefetch** — warm the cache before a screen appears so images render instantly — the instance can walk a screen's DSL and hand you exactly the asset (and font) references it needs:

- `collectAssetReferences(screenId:)` / `collectAllAssetReferences()` — enumerate referenced assets
- `prefetchImages(forScreens:)` / `prefetchAllImages()` — warm the URL cache

This keeps delivery lean: only what a screen actually references is fetched, not the whole catalog.

---

## Live Updates & Streaming

The streaming methods let content change *after* a screen is on screen — for live editing, server-pushed updates, or collaboration. Each returns an `AsyncStream<Data>?`; return `nil` to opt out.

| Stream | Granularity | Effect |
|--------|-------------|--------|
| `streamScreen(screenId:)` | Whole screen | Re-renders the screen with a new definition (structural) |
| `streamDatasource(screenId:datasourceId:componentPath:)` | Data only | Updates bound variable values — **no re-render** (fast path) |
| `streamStyles()` | Style primitives | Re-applies all styles without reloading screens |

Prefer `streamDatasource` for value changes (a price ticking, a list growing) — it skips the structural rebuild. Reserve `streamScreen` for layout changes.

---

## Receiving Events

DSL screens fire two independent typed streams into the host. Both are documented in depth on their own pages; this is the orientation.

| Bus | Carries | Wire it for | Reference |
|-----|---------|-------------|-----------|
| **Event bus** | `.emit` action events authored in the DSL | Host behavior — start a checkout, open a sheet, mark a step done | [events.md](events.md) |
| **Analytics bus** | Auto `app8.*` lifecycle events + author-declared `analytics` bindings | Product analytics — proxy to Mixpanel / Amplitude / Segment | [analytics.md](analytics.md) |

To run host-side logic in response to a tap, the DSL author emits an event:

```json
"actions": { "tap": { "type": "emit", "name": "checkout.tapped", "payload": { "sku": "{{item.sku}}" } } }
```

…and the host routes it by `event.name`. This `.emit` → event-bus path is the supported way for DSL to trigger native code. (`executeFunction` is a reserved action consumed by higher-level delivery SDKs, not the core engine.) When the native code needs its own view inside the screen, use a [native component](#native-components).

---

## Native Components

A [`native`](components/native.md) component embeds a view the host provides. The DSL names a `module`, passes `props` (expressions, re-resolved when variables change) and maps the module's events to actions; the host registers one factory per module:

| Platform | Registration | The view gets |
|----------|--------------|---------------|
| iOS | `App8.registerNativeComponent("signaturePad") { context in UIView }` | `App8NativeContext`: `props`, `onPropsChange`, `emit(_:_:)`, `appId`, `screenId` |
| Android | `App8Config(nativeComponents = mapOf("signaturePad" to App8NativeComponent { context, modifier -> … }))` | `App8NativeContext(props, emit, appId, screenId)` + `Modifier` |
| Web | `registerNativeComponent("signaturePad", Component)` in the web renderer | `NativeComponentProps`: `props`, `emit`, `width`, `height`, `platform`, `appId` |

When the module calls `emit("completed", payload)`, the engine runs the component's `actions.completed` with the payload in scope as `event`, and posts `native.signaturePad.completed` on the event bus, so the host can also observe it with `subscribe(to:)`. When no factory is registered for the module, the component renders its DSL `fallback` (or nothing, with a `native.module.missing` warning).

Modules usually need data the engine does not have (an auth token, an upload endpoint). Give it to the module in the factory closure, not through props: props come from the bundle and are visible to every author.

---

## Localization

The host owns the active locale. `getTranslations()` supplies the bundle once at boot; `instance.setLocale(_:)` switches language at runtime; `instance.currentLocale` reports the resolved locale. See [localization.md](localization.md) for the bundle shape and fallback chain.

---

## See Also

- [README Quick Start](../../README.md#quick-start) — bootstrapping an instance
- [events.md](events.md) — the `.emit` event bus and subscribe API
- [components/native.md](components/native.md) — the `native` component: props, events, fallback
- [prefabs.md](prefabs.md) — feature packages and the native modules they require
- [analytics.md](analytics.md) — analytics events and handler wiring
- [localization.md](localization.md) — translation bundle and locale resolution
- [variables.md](variables.md) — `source` bindings and datasource-backed variables
