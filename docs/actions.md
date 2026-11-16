# Actions & Events

Actions are triggered by user interactions or lifecycle events.

> **Forwarding events to the host?** See [events.md](events.md) for the `.emit` action and the typed `App8.Instance.subscribe(...)` API. See [analytics.md](analytics.md) for the analytics bus.

## Action Triggers

### Component Actions

```json
{
  "actions": {
    "tap": { "type": "navigation", "nextScreen": "details" }
  }
}
```

A trigger may also list **multiple actions** to run in JSON order:

```json
{
  "actions": {
    "tap": [
      { "type": "emit",       "name": "checkout.started", "payload": { "cart": "{{cartId}}" } },
      { "type": "navigation", "nextScreen": "confirm" }
    ]
  }
}
```

### Trigger Types

| Trigger | Components | When Fired |
|---------|------------|------------|
| `tap` | Button, View | User taps |
| `longPress` | Button, View | User long-presses. A `contextMenu` on the same component replaces it ([context-menu.md](context-menu.md)) |
| `onTextChange` | TextField, TextView | Text value changes |
| `onItemTap` | Collection | Collection item tapped |
| `onRefresh` | Collection | Pull-to-refresh triggered |
| `onLoadMore` | Collection | Pagination threshold reached |
| `onSelectionChange` | Collection | Selection changed |
| `onScrollThreshold` | ScrollView | Scroll crosses a configured threshold |
| `onAnnotationTap` | Map | Map annotation tapped |
| `onRegionChange` | Map | Visible map region changed |
| `onUserLocationUpdate` | Map | User location updated |
| `onVideoReady` | Video | Item is ready to play (before first frame) |
| `onVideoStart` | Video | Playback starts (first time it begins playing) |
| `onVideoPause` | Video | Playback pauses |
| `onVideoComplete` | Video | A non-looping clip plays to its end |
| `onVideoLoop` | Video | A looping clip completes a cycle (overlay `$loopCount`) |
| `onVideoStall` | Video | Playback stalls waiting to buffer |
| `onVideoError` | Video | The item fails to load/decode (overlay `$error`) |
| `onTimeMark` | Video | Playback crosses a configured `marks` time (overlay `$markId`) |

> Every trigger in this table also accepts an `analytics:` map alongside `actions:` — the engine fires the analytics binding regardless of whether `actions` is present. See [`analytics.md`](analytics.md).

---

## Navigation Actions

### Navigate to Screen

```json
{
  "type": "navigation",
  "nextScreen": "profileScreen",
  "params": { "userId": "{{selectedId}}" },
  "presentation": "push"
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `nextScreen` | string | | Screen ID to navigate to |
| `params` | object | | Parameters to pass |
| `presentation` | Presentation | `push` | Presentation style |
| `transition` | Transition | | Custom screen transition — see [transitions.md](transitions.md) |

### Presentation Styles

| Style | Description |
|-------|-------------|
| `push` | Standard navigation push (default) |
| `sheet` | iOS-style bottom sheet with detents |
| `fullScreen` | Full screen modal |
| `formSheet` | Smaller modal (iPad-optimized) |
| `pageSheet` | Page sheet modal |
| `crossDissolve` | Full screen modal with a fade transition |

### Examples

```json
{
  "type": "navigation",
  "nextScreen": "details"
}
```

```json
{
  "type": "navigation",
  "nextScreen": "editProfile",
  "presentation": "sheet"
}
```

```json
{
  "type": "navigation",
  "nextScreen": "fullScreenImage",
  "params": { "imageUrl": "{{item.imageUrl}}" },
  "presentation": "fullScreen"
}
```

### Dismiss Modal

Close the current modal screen.

```json
{
  "type": "dismiss"
}
```

#### Dismiss, then navigate

In one action list, a `navigation` after `dismiss` waits until the modal has
finished dismissing, then runs from the **presenting** screen: a push lands on the
presenting screen's navigation stack, a modal presentation is presented by it, and
`isBack` pops that stack. The result is the same on every platform: the modal goes
away first, then the new screen appears, with no frame where both animate at once.

```json
{
  "actions": {
    "tap": [
      { "type": "dismiss" },
      { "type": "navigation", "nextScreen": "noteDetails", "params": { "noteId": "{{note.id}}" } }
    ]
  }
}
```

Precisely: after a `dismiss`, the list pauses before its next `navigation` action
until the modal is gone, then continues in order with that navigation. Actions
between the two run right away. Run variable updates **before** `dismiss`, and do
not read the modal screen's own variables in the `navigation` or anything after it:
the modal is gone by the time they run. To carry
a value from the modal into the next screen, bind it first with [`with`](#with),
whose values are evaluated once, before the dismissal:

```json
{
  "type": "with",
  "values": { "noteId": "{{draftNote.id}}" },
  "actions": [
    { "type": "dismiss" },
    { "type": "navigation", "nextScreen": "noteDetails", "params": { "noteId": "{{noteId}}" } }
  ]
}
```

### Complete Flow

Finish current flow and navigate to another flow.

```json
{
  "type": "completeFlow",
  "destination": "main"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `destination` | string | Flow ID to navigate to |

### Select Tab

Switch to a tab in TabBarScreen.

By ID:
```json
{
  "type": "selectTab",
  "tabId": "profile"
}
```

By index:
```json
{
  "type": "selectTab",
  "tabIndex": 2
}
```

---

## Variable Actions

### Update Single Variable

```json
{
  "type": "updateVariable",
  "variableName": "count",
  "value": "{{count + 1}}"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `variableName` | string | Variable to update |
| `value` | any/expression | New value |
| `key` | string/expression | Optional. With an `object` variable: set only this key, keep the others. E.g. `"key": "{{product.handle}}"` writes one product's chosen variant into `selectedVariants` |

### Increment Number

```json
{
  "type": "incrementVariable",
  "variableName": "count",
  "by": 1
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `variableName` | string | | Variable to increment |
| `by` | number/expression | 1 | Amount to add. Accepts an expression that gives a number, e.g. `"{{line.quantity}}"` |

### Toggle Array Value

Add value if missing, remove if present.

```json
{
  "type": "toggleArrayValue",
  "variableName": "selectedIds",
  "value": "{{item.id}}"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `variableName` | string | Array variable |
| `value` | any/expression | Value to toggle |

For arrays of objects, use `matchBy` to identify entries by key (e.g. `"matchBy": "id"`).

### Append To Array

Append a value to the end of an array variable (no de-duplication).

```json
{
  "type": "appendToArray",
  "variableName": "messages",
  "value": "{{draftText}}"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `variableName` | string | Array variable |
| `value` | any/expression | Value to append |

### Increment Array Item

Adjust a numeric field of the object in an array matched by `matchBy` — one
action for a cart's add, +, − and remove-at-zero.

```json
{
  "type": "incrementArrayItem",
  "variableName": "cart",
  "matchBy": "key",
  "value": { "key": "{{product.handle}}", "title": "{{product.title}}", "unitPrice": "{{product.priceValue}}" },
  "by": 1
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `variableName` | string | | Array variable |
| `matchBy` | string | | Object key that identifies an item |
| `value` | object / any | | The full object (its `matchBy` key matches; appended with `field = by` when missing and `by > 0`) or just the key value |
| `field` | string | `"quantity"` | Numeric field to adjust |
| `by` | number/expression | `1` | Amount to add (negative to decrement); an expression must give a number. An item whose field drops to `0` or below is removed |

Object `value`s may contain `{{expressions}}` at any depth; they resolve when the
action runs.

When the resolved match key is `null` or missing (an object `value` without its
`matchBy` key, or a key expression that resolves to `null`), the action does
nothing: no item is added, adjusted or removed.

### Insert Array Item

Insert a value at a position in an array variable.

```json
{
  "type": "insertArrayItem",
  "variableName": "recentSearches",
  "value": "{{query}}",
  "index": 0
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `variableName` | string | | Array variable |
| `value` | any/expression | | Value to insert. Objects may contain expressions at any depth |
| `index` | number/expression | `0` | Position of the new element. `0` prepends. A negative index counts from the end: `-1` appends, `-2` inserts before the last element. The index is clamped to `[0, count]`, so a large index appends |

### Upsert Array Item

Replace the object whose `matchBy` key equals the value's, or add it when there is
none: a "recently viewed" list, a saved address book, a per-item note.

```json
{
  "type": "upsertArrayItem",
  "variableName": "recentlyViewed",
  "matchBy": "id",
  "value": { "id": "{{photo.id}}", "title": "{{photo.title}}", "viewedAt": "{{now()}}" },
  "position": "start"
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `variableName` | string | | Array variable |
| `matchBy` | string | | Object key that identifies an element |
| `value` | object | | The new element. Its `matchBy` key is the match key |
| `position` | string | `"end"` | Where a new element goes when nothing matches: `"start"` or `"end"` |

- The **first** element whose `matchBy` key equals `value[matchBy]` is replaced by
  `value` exactly: fields of the old element that `value` does not have are dropped,
  and the element keeps its position.
- No match: `value` is inserted at `position`.
- A `null` or missing match key makes the action a no-op (same rule as
  `incrementArrayItem`).

### Remove Array Item

Remove elements by key, or one element by position.

```json
{
  "type": "removeArrayItem",
  "variableName": "tasks",
  "matchBy": "key",
  "value": "{{task.key}}"
}
```

```json
{
  "type": "removeArrayItem",
  "variableName": "recentSearches",
  "index": -1
}
```

| Property | Type | Description |
|----------|------|-------------|
| `variableName` | string | Array variable |
| `matchBy` | string | With `value`: object key that identifies elements |
| `value` | any/expression | With `matchBy`: the key value. **Every** element whose `matchBy` key equals it is removed. An object `value` uses its own `matchBy` key, as in `incrementArrayItem` |
| `index` | number/expression | Remove the element at this position instead. Negative counts from the end (`-1` is the last element). Out of range: no-op |

When both `index` and `matchBy` are present, `index` wins. A `null` or missing
match key, or an `index` out of range, makes the action a no-op.

### Array action rules

These rules hold for `appendToArray`, `insertArrayItem`, `upsertArrayItem`,
`removeArrayItem` and `incrementArrayItem`:

- A variable whose value is `null` (or not set yet) counts as an empty array.
- `matchBy` keys compare the same way in every array action: equal strings, equal
  numbers or equal booleans match.
- Each action writes a new array to the variable once, so readers update once per
  action.

### Update Multiple Variables

```json
{
  "type": "updateMultipleVariables",
  "updates": {
    "isLoading": false,
    "hasError": true,
    "errorMessage": "Failed to load"
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `updates` | object | Key-value pairs to update |

### Reset Variables

Reset variables to initial values.

```json
{
  "type": "resetVariables",
  "scope": "screen"
}
```

Restores each variable to its **initial value** — the value it had right after definition (an `initialValue` expression, datasource or navigation param is restored to what it resolved to then). Variables are never removed; computed variables recompute.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `scope` | Scope | `screen` | Which variables to reset |

### Scope Values

Scopes are relative to the component running the action.

| Value | Description |
|-------|-------------|
| `component` | That component's own local variables |
| `screen` | Its own, every enclosing component's and the screen's variables (everything except app-level) |
| `app` | App-level variables |
| `all` | All of the above |

---

## State Actions

### Set Component State

```json
{
  "type": "setState",
  "stateName": "active",
  "animated": true
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `stateName` | string | | State to transition to |
| `animated` | boolean | true | Animate transition |

See [states.md](states.md) for state definitions.

---

## Focus Actions

### Focus Specific Component

```json
{
  "type": "focus",
  "target": "emailField"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `target` | string | Component ID to focus |

### Focus Next

Move focus to next focusable component.

```json
{
  "type": "focusNext"
}
```

### Focus Previous

Move focus to previous focusable component.

```json
{
  "type": "focusPrevious"
}
```

### Dismiss Keyboard

Hide the keyboard.

```json
{
  "type": "dismissKeyboard"
}
```

---

## Feedback & System Actions

### Show Alert

Present a native alert.

```json
{
  "type": "showAlert",
  "alertTitle": "Delete item?",
  "alertMessage": "This cannot be undone.",
  "alertActions": [
    { "title": "Cancel", "style": "cancel" },
    { "title": "Delete", "style": "destructive", "action": { "type": "executeFunction", "function": "deleteItem" } }
  ]
}
```

| Property | Type | Description |
|----------|------|-------------|
| `alertTitle` | string | Alert title |
| `alertMessage` | string | Alert body text |
| `alertActions` | AlertAction[] | Buttons (`title`, `style`, optional nested `action`) |

`style` is one of `default`, `cancel`, `destructive`.

### Haptic

Trigger haptic feedback.

```json
{
  "type": "haptic",
  "hapticStyle": "success"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `hapticStyle` | string | `light`, `medium`, `heavy`, `success`, `warning`, `error`, `selection` |

### Open URL

Open a URL. `url` supports expressions.

```json
{
  "type": "openURL",
  "url": "https://example.com/{{slug}}",
  "urlPresentation": "sheet"
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `url` | string/expression | | URL to open |
| `urlPresentation` | string | `external` | `external` (system handler), `sheet`, or `fullScreen` (in-app Safari) |

### Request Notification Permission

Ask the user for permission to send notifications (the system prompt), then run
`onGranted` or `onDenied`. The prompt shows only the first time; after the user
has answered, the action answers at once with the stored choice (iOS and
Android don't ask twice). The rest of the action list continues straight away,
like `request`: put what depends on the answer in `onGranted` / `onDenied`.

```json
{
  "type": "requestNotificationPermission",
  "onGranted": [
    { "type": "toggleArrayValue", "variableName": "remindedIds", "value": "{{item.id}}" },
    { "type": "haptic", "hapticStyle": "success" }
  ],
  "onDenied": []
}
```

| Property | Type | Description |
|----------|------|-------------|
| `onGranted` | Action \| Action[] | Runs when notifications are allowed (now, or earlier) |
| `onDenied` | Action \| Action[] | Runs when the user declines (now, or earlier) |

| Platform | What it does |
|----------|--------------|
| iOS | `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])` when the status is `.notDetermined`; otherwise reads the current status. Provisional and ephemeral count as granted. Registering for remote pushes is up to the host |
| Android | 13+ (API 33): the `POST_NOTIFICATIONS` runtime permission dialog (the engine's manifest declares the permission). Older versions: granted when `NotificationManagerCompat.areNotificationsEnabled()` |
| Web renderer | A simulated system prompt drawn the platform's way; the answer is kept per app (`app8:<appId>:permission.notifications` in `localStorage`) |

To remember a per-item answer, write to a persisted app
variable in `onGranted` (see [variables.md → Persisted Variables](variables.md#persisted-variables)).

---

## Function Actions

### Execute Backend Function

Invoke a named function by reference.

```json
{
  "type": "executeFunction",
  "function": "submitForm",
  "params": {
    "email": "{{email}}",
    "password": "{{password}}"
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `function` | string | Function name |
| `params` | object | Parameters to pass |

> **Engine support**: `executeFunction` is a **no-op in the core engine** — it is reserved for higher-level delivery SDKs (e.g. the cloud SDK) that wire function names to real handlers. If you only use App8Engine directly, this action does nothing. **To trigger host-side logic, use [`emit`](events.md)** — it dispatches a typed event to the host event bus, which is the supported integration point. See [host-integration.md](host-integration.md).

---

## Control Flow Actions

### forEach

Run nested actions once per element of an array.

```json
{
  "type": "forEach",
  "items": "{{selectedTasks}}",
  "as": "task",
  "index": "i",
  "actions": [
    { "type": "incrementArrayItem", "variableName": "tasks", "matchBy": "key", "value": { "key": "{{task.key}}" }, "field": "count", "by": 1 }
  ]
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `items` | expression | | The array to walk |
| `as` | string | `"item"` | Name of the current element inside `actions` |
| `index` | string | | Optional name of the current position (0-based) inside `actions` |
| `actions` | Action / Action[] | | Actions to run for each element |

- `items` is evaluated **once**, before the first iteration. Actions that change the
  source variable during the loop do not add, skip or repeat iterations.
- Iterations run in order. Each iteration runs its `actions` like an action list,
  to the end, before the next iteration starts. Asynchronous actions (such as
  [`request`](#request)) start in their iteration and do not hold up the next one.
- The element and index names shadow outer names of the same name (an `item` from a
  collection, a screen variable) inside the nested actions only. They are read-only:
  variable actions still write to real variables.
- `null` or a non-array `items` runs nothing. An empty array runs nothing.
- `forEach` can be nested; give the inner loop a different `as`.

### with

Bind names for nested actions.

```json
{
  "type": "with",
  "values": { "book": "{{item.book}}", "count": 1 },
  "actions": [
    { "type": "upsertArrayItem", "variableName": "readingList", "matchBy": "key", "value": { "key": "{{book.id}}", "title": "{{book.title}}", "count": "{{count}}" } }
  ]
}
```

| Property | Type | Description |
|----------|------|-------------|
| `values` | object | Names and their values. Values are literals or expressions; objects and arrays resolve expressions at any depth, and a whole-string expression keeps its type |
| `actions` | Action / Action[] | Actions that run with `values` in scope |

`values` is evaluated **once**, against the current scope, before the first nested
action runs. Inside `actions` the names shadow outer names of the same name; outside
`with` they do not exist. Like loop names they are read-only.

`with` lets one reusable action list receive different inputs at each place it is
used: a [prefab](prefabs.md) param supplies the list once, and each call site wraps
it in a `with` that binds the names the list reads.

---

## Network Actions

### request

Make an HTTP request from the DSL.

```json
{
  "type": "request",
  "method": "DELETE",
  "url": "https://api.example.com/v1/items/{{item.id}}",
  "headers": { "Accept": "application/json" },
  "body": { "note": "{{note}}" },
  "resultVariable": "lastResponse",
  "onSuccess": [
    { "type": "removeArrayItem", "variableName": "items", "matchBy": "id", "value": "{{item.id}}" }
  ],
  "onError": [
    { "type": "updateVariable", "variableName": "errorMessage", "value": "{{response.body.message}}" }
  ]
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `method` | string | `"GET"` | `GET`, `POST`, `PUT`, `PATCH` or `DELETE` |
| `url` | string/expression | | Absolute `https://` or `http://` URL. Interpolates like `openURL` |
| `headers` | object | | Header names and values. Values accept expressions |
| `body` | any | | JSON body: an object, an array or an expression. Objects and arrays resolve expressions at any depth. Sent as `application/json` |
| `resultVariable` | string | | Variable that receives the `response` object |
| `onSuccess` | Action / Action[] | | Runs after a 2xx response |
| `onError` | Action / Action[] | | Runs after any other status, a network failure, a timeout or a host rejection |

**The `response` object.** While `onSuccess` or `onError` run, `response` is in scope:

| Field | Type | Description |
|-------|------|-------------|
| `response.status` | number | HTTP status code. `0` for a network failure, a timeout or a host rejection |
| `response.body` | any | The body parsed as JSON; the raw string when it is not JSON; `null` when empty or when there was no response |
| `response.headers` | object | Response headers, names lowercased (`response.headers["content-type"]`). `{}` when there was no response |

`resultVariable` receives the same object, written before `onSuccess` / `onError`
run. It follows the [`updateVariable`](#update-single-variable) rules for which
variable it writes.

Rules:

- **Success** is a 2xx status. Everything else is an error, including 3xx that
  are not followed, 4xx, 5xx and status `0`. Redirects are followed.
- **Body.** `GET` requests send no body (a `body` on a `GET` is ignored). For the
  other methods, a present `body` is serialized as JSON and the engine sets
  `Content-Type: application/json`.
- **Timeout** is 30 seconds. A timeout is an error with status `0`.
- **Asynchronous.** `request` starts the request and the rest of the action list
  continues immediately, without waiting for the response. Put actions that depend
  on the response in `onSuccess` / `onError`.
- **Lifetime.** `onSuccess` and `onError` run only while the screen that started the
  request is still alive (on a navigation stack or presented). When the screen has
  been removed, the callbacks are dropped, and so is a `resultVariable` write to a
  screen or component variable. A `resultVariable` that is an **app** variable is
  always written, even when the screen is gone. Other work that must outlive the
  screen belongs in the host: [`emit`](events.md) an event instead.
- **Host hook.** Before it is sent, every request goes through the host's
  `prepareRequest` hook, which can add authorization, rewrite the URL or reject the
  request (an error with status `0`). See
  [host-integration.md](host-integration.md#http-requests-from-the-dsl).
- Never put secrets (API keys, tokens) in the bundle; the host adds them in
  `prepareRequest`.

### reloadDatasource

Fetch a datasource again and update every variable bound to it.

```json
{
  "type": "reloadDatasource",
  "source": "datasources/items"
}
```

| Property | Type | Description |
|----------|------|-------------|
| `source` | string | The datasource path, exactly as written in the variables' `source` field |
| `onSuccess` | Action / Action[] | Optional. Runs after the variables are updated |
| `onError` | Action / Action[] | Optional. Runs after the fetch failed |

The engine asks the host data source for fresh data for `source` once
([`reloadDatasource(screenId:datasourceId:)`](host-integration.md#datasources), with
the id of the screen that runs the action; it defaults to `getDatasource`, and a data
source that caches bypasses its cache there), then writes the result into every variable
whose `source` is that path: app variables and the variables of every screen that
is currently alive. Computed variables and collections that read them update as
usual. Persisted app variables store the new value.

Like `request`, the reload is asynchronous: the action list continues immediately.
Put actions that need the fresh data in `onSuccess`, which runs once every bound
variable has its new value. When the fetch fails, the variables keep their values,
the engine logs a `datasource.reload.failed` warning, and `onError` runs. Both
follow the `request` lifetime rule: they run only while the screen that started the
reload is still alive.

A common pair: delete on the server, then refresh the list.

```json
{
  "type": "request",
  "method": "DELETE",
  "url": "https://api.example.com/v1/items/{{item.id}}",
  "onSuccess": { "type": "reloadDatasource", "source": "datasources/items" }
}
```

---

## Event Triggers

Screen lifecycle and timer events.

### Event Structure

```json
{
  "onEvent": [
    {
      "event": "eventType",
      "action": { }
    }
  ]
}
```

### Event Types

| Event | When |
|-------|------|
| `appear` | Screen appeared |
| `disappear` | Screen will disappear |
| `timer` | Timer fired |

### On Appear

```json
{
  "onEvent": [
    {
      "event": "appear",
      "action": { "type": "executeFunction", "function": "loadData" }
    }
  ]
}
```

### On Disappear

```json
{
  "onEvent": [
    {
      "event": "disappear",
      "action": { "type": "executeFunction", "function": "cleanup" }
    }
  ]
}
```

### Timer Event

```json
{
  "onEvent": [
    {
      "event": "timer",
      "delay": 2.0,
      "interval": 5.0,
      "repeats": true,
      "action": { "type": "executeFunction", "function": "refresh" }
    }
  ]
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `delay` | number | 0 | Initial delay in seconds |
| `interval` | number | | Repeat interval (if repeats) |
| `repeats` | boolean | false | Whether to repeat |

---

## Action Arrays

Execute multiple actions in sequence, in JSON order. [`request`](#request) and
[`reloadDatasource`](#reloaddatasource) start their work and let the list continue
(their results arrive later). After a [`dismiss`](#dismiss-then-navigate), the list
pauses before its next `navigation` until the modal is gone.

```json
{
  "actions": {
    "tap": [
      { "type": "updateVariable", "variableName": "isLoading", "value": true },
      { "type": "executeFunction", "function": "submit" },
      { "type": "dismissKeyboard" }
    ]
  }
}
```

---

## Complete Examples

### Login Form Submit

<!-- @dsl-type: Component -->
```json
{
  "type": "button",
  "content": {
    "properties": {
      "text": "Sign In",
      "isEnabled": "{{email.length > 0 && password.length > 0}}"
    },
    "actions": {
      "tap": [
        { "type": "dismissKeyboard" },
        { "type": "updateVariable", "variableName": "isLoading", "value": true },
        {
          "type": "executeFunction",
          "function": "signIn",
          "params": {
            "email": "{{email}}",
            "password": "{{password}}"
          }
        }
      ]
    }
  }
}
```

### Like Button Toggle

<!-- @dsl-type: Component -->
```json
{
  "type": "button",
  "content": {
    "properties": {
      "icon": "{{likedIds.includes(item.id) ? 'heart.fill' : 'heart'}}"
    },
    "actions": {
      "tap": {
        "type": "toggleArrayValue",
        "variableName": "likedIds",
        "value": "{{item.id}}"
      }
    }
  }
}
```

### Form Field Navigation

Use `returnKeyType` to configure the keyboard return key. Focus flows to the next field automatically based on field order, or use explicit focus actions on buttons:

```json
{
  "children": [
    {
      "type": "textField",
      "id": "emailField",
      "content": {
        "properties": {
          "returnKeyType": "next",
          "bindVariable": "email"
        }
      }
    },
    {
      "type": "textField",
      "id": "passwordField",
      "content": {
        "properties": {
          "returnKeyType": "done",
          "bindVariable": "password",
          "isSecure": true
        }
      }
    },
    {
      "type": "button",
      "content": {
        "properties": { "text": "Submit" },
        "actions": {
          "tap": [
            { "type": "dismissKeyboard" },
            { "type": "executeFunction", "function": "submit" }
          ]
        }
      }
    }
  ]
}
```

Focus can also be controlled explicitly:

```json
{
  "type": "button",
  "content": {
    "properties": { "text": "Focus Password" },
    "actions": {
      "tap": { "type": "focus", "target": "passwordField" }
    }
  }
}
```

### Modal Dismiss with Confirmation

```json
{
  "type": "button",
  "content": {
    "properties": { "text": "Cancel" },
    "actions": {
      "tap": [
        { "type": "resetVariables", "scope": "screen" },
        { "type": "dismiss" }
      ]
    }
  }
}
```

### Tab Navigation with State

```json
{
  "type": "button",
  "content": {
    "properties": { "text": "Go to Profile" },
    "actions": {
      "tap": [
        { "type": "selectTab", "tabId": "profile" },
        { "type": "updateVariable", "variableName": "profileTab.shouldRefresh", "value": true }
      ]
    }
  }
}
```

### Screen Load with Timer

```json
{
  "type": "screen",
  "content": {
    "onEvent": [
      {
        "event": "appear",
        "action": { "type": "executeFunction", "function": "loadInitialData" }
      },
      {
        "event": "timer",
        "delay": 0,
        "interval": 30,
        "repeats": true,
        "action": { "type": "executeFunction", "function": "refreshData" }
      }
    ]
  }
}
```
