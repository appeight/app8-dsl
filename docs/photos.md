# Photos

Let the user take or pick a photo, keep it on the device, and show it later:
a profile picture, a dated photo log, a picture on a saved item.

Three pieces:

1. The [`capturePhoto`](#capturephoto) action opens the camera or the photo library,
   downscales the result, stores it on the device and hands back a **photo
   reference**, a short string like `photo://3f2b9c1e-6a4d-4e2f-9b1a-7c8d9e0f1a2b`.
2. The app keeps that string where it keeps any other data: a
   [persisted variable](variables.md#persisted-variables), or a field of an item in a
   persisted list.
3. An [`image`](components/image.md#photo-references) shows it: `"url": "{{entry.photo}}"`.

[`deletePhoto`](#deletephoto) removes a file at once. Photos that no persisted
variable mentions any more are removed at the next launch
([cleanup](#cleanup)), and the host's data reset removes them all
([reset](#reset)).

## Example: a dated photo log

```json
{
  "variables": {
    "entries": { "type": "array", "initialValue": [], "persist": true }
  }
}
```

The add button:

```json
{
  "type": "capturePhoto",
  "source": "cameraOrLibrary",
  "camera": "back",
  "aspectRatio": 1,
  "onSuccess": {
    "type": "insertArrayItem",
    "variableName": "entries",
    "index": 0,
    "value": { "id": "{{photo.ref}}", "photo": "{{photo.ref}}", "date": "{{photo.createdAt}}" }
  },
  "onError": {
    "type": "showAlert",
    "alertTitle": "No camera access",
    "alertMessage": "Allow camera access in Settings to add photos.",
    "alertActions": [{ "title": "OK", "style": "cancel" }]
  }
}
```

The list item (`entry` is the collection's item variable):

```json
{
  "type": "image",
  "content": { "properties": { "url": "{{entry.photo}}" } },
  "style": { "contentMode": "scaleAspectFill" }
}
```

The delete action on an item:

```json
[
  { "type": "removeArrayItem", "variableName": "entries", "matchBy": "id", "value": "{{entry.id}}" },
  { "type": "deletePhoto", "ref": "{{entry.photo}}" }
]
```

## `capturePhoto`

```json
{
  "type": "capturePhoto",
  "source": "camera",
  "camera": "front",
  "aspectRatio": 1,
  "maxDimension": 1024,
  "resultVariable": "avatar",
  "onSuccess": { "type": "haptic", "hapticStyle": "success" },
  "onCancel": [],
  "onError": { "type": "updateVariable", "variableName": "photoError", "value": "{{error.code}}" }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `source` | string | `"cameraOrLibrary"` | `camera`, `library`, or `cameraOrLibrary`: a chooser (action sheet on iOS, bottom sheet on Android) with both. Where there is no camera, `cameraOrLibrary` opens the library directly |
| `camera` | string | `"back"` | `back` or `front`: the camera that opens first. The user can still switch |
| `aspectRatio` | number/expression | | Optional width ÷ height. The photo is center-cropped to it (`1` square, `0.75` portrait 3:4). Without it the photo keeps its shape |
| `maxDimension` | number/expression | `1600` | Longest side in pixels after downscaling. Clamped to `256`…`4096`. Smaller photos are not enlarged |
| `quality` | number/expression | `0.8` | JPEG quality, `0.1`…`1` |
| `labels` | object | | Optional chooser texts (expressions): `camera` (default "Take Photo"), `library` ("Choose from Library"), `cancel` ("Cancel") |
| `resultVariable` | string | | Variable that receives the photo reference string. Follows the [`updateVariable`](actions.md#update-single-variable) rules |
| `onSuccess` | Action / Action[] | | Runs after the photo is stored, with `photo` in scope |
| `onCancel` | Action / Action[] | | Runs when the user closes the camera, the library or the chooser without a photo |
| `onError` | Action / Action[] | | Runs when there is no permission, no camera, or the photo could not be read or stored, with `error` in scope |

**The `photo` object** (in `onSuccess`):

| Field | Type | Description |
|-------|------|-------------|
| `photo.ref` | string | The photo reference, `photo://<id>`. Store this |
| `photo.width` | number | Stored width in pixels |
| `photo.height` | number | Stored height in pixels |
| `photo.createdAt` | string | When it was captured, ISO 8601 in UTC (`2026-11-18T09:41:00Z`). Formats with [`formatDate`](variables.md#date--time) |
| `photo.source` | string | `camera` or `library`: where the user took it from |

**The `error` object** (in `onError`):

| Field | Type | Description |
|-------|------|-------------|
| `error.code` | string | `permissionDenied`: the user (now or earlier) or a device policy refused camera access. `unavailable`: no camera, or the host app is not set up for it ([host setup](#host-setup)). `failed`: the image could not be read or stored |
| `error.message` | string | A developer-facing description. Not for display |

Rules:

- **Asynchronous.** Like [`request`](actions.md#request), `capturePhoto` opens its UI
  and the rest of the action list continues at once. Put what needs the photo in
  `onSuccess`.
- **Lifetime.** The callbacks follow the `request` lifetime rule: they run only while the
  screen that started the capture is alive. An app `resultVariable` is always written.
- **One at a time.** While a capture is open, another `capturePhoto` is ignored
  (diagnostic `photo.capture.busy`).
- **Permission.** The camera asks for permission the first time it opens. After a
  refusal the engine does not ask again: `onError` runs at once with
  `permissionDenied`. Show the user how to allow it (an alert, a button that opens
  settings). Picking from the library needs no permission on any platform: the
  system pickers only hand over the photo the user chose.
- **What is stored.** A JPEG, upright (orientation applied to the pixels), sRGB,
  without metadata (no location, no camera details), downscaled to
  `maxDimension`, cropped to `aspectRatio`. A 1600 px photo at quality 0.8 is
  typically 200–400 KB.
- **Not uploaded.** Photos stay on the device. Nothing in the engine sends them
  anywhere.

## `deletePhoto`

```json
{ "type": "deletePhoto", "ref": "{{entry.photo}}" }
```

| Property | Type | Description |
|----------|------|-------------|
| `ref` | string/expression | The photo reference. A `null`, a value that is not a `photo://` reference, or a photo that no longer exists makes the action a no-op |

The file is removed at once; images that show it become empty. Variables that hold
the reference keep it: remove it from them in the same action list (the reference of
a deleted photo is harmless, it shows nothing).

## Photo references

- A reference is the string `photo://` followed by an id. Treat it as opaque: store
  it, compare it, pass it to `image` and `deletePhoto`. Do not build one yourself.
- A reference is only meaningful on the device and in the app that created it. A
  reference copied to another device, or into another app's bundle, shows nothing.
- Any variable can hold one. Only [persisted](variables.md#persisted-variables)
  variables keep the photo alive across launches ([cleanup](#cleanup)).

## Showing a photo

An [`image`](components/image.md#photo-references) whose `url` (or `name`) is a
photo reference shows the stored photo with the image's usual `contentMode`,
corners and styles. A `null` or empty value, or a deleted photo, draws nothing
(the image's background still shows), so a placeholder behind it or an
`isHidden: "{{entry.photo == null}}"` works as with any image.

## Cleanup

When an app starts, after its persisted variables are loaded, the engine deletes the
app's stored photos whose reference appears in no persisted variable of that app and
that are older than one hour. So removing an item with `removeArrayItem`,
overwriting a variable or `resetVariables` frees its photo by the next launch without
a `deletePhoto`. A photo kept only in a screen variable, or only outside the
engine, does not survive a relaunch.

## Reset

Photos belong to the device, like [persisted variables](variables.md#persisted-variables).
`App8.clearPersistedData()` (iOS) / `App8.clearPersistedData(context)` (Android) /
`clearPersistedData()` (web renderer) removes every app's stored photos together with
the stored variables. A host with sign-in calls it when its signed-in user changes.

## Storage

Per app, under the same app id as persisted variables:

| Platform | Location |
|----------|----------|
| iOS | `Application Support/app8/<appId>/photos/<id>.jpg` |
| Android | `filesDir/app8/<appId>/photos/<id>.jpg` (app-private; camera handoff through the engine's `FileProvider`) |
| Web renderer | IndexedDB database `app8:<appId>:photos`, object store `photos`, key `<id>`, value a JPEG `Blob`; an image loads it through an object URL |

## Host setup

| Platform | What the host does |
|----------|--------------------|
| iOS | Add `NSCameraUsageDescription` to the app's `Info.plist` (the text the permission prompt shows). Without it the camera is `unavailable` (diagnostic `photo.camera.usageDescriptionMissing`) instead of crashing. The library uses `PHPickerViewController`: no `NSPhotoLibraryUsageDescription` needed |
| Android | Nothing. The engine takes the photo with the system camera app (`ACTION_IMAGE_CAPTURE`) and picks with the system Photo Picker; neither needs a permission. If the host's manifest declares `android.permission.CAMERA` (for its own camera features), Android requires it for the system camera too, and the engine asks for it first |
| Web renderer | Serve over HTTPS (camera access needs a secure context). The camera opens in the page with `getUserMedia`; without a camera, or where the browser has none, the camera falls back to the system file picker (`<input type="file" accept="image/*" capture>`), which mobile browsers open as their camera |

The `camera` property picks the camera to open on iOS and the web renderer. On Android
it is passed to the system camera app as a hint, which most camera apps follow.

## DSL side and SDK side

| Part | Side | Why |
|------|------|-----|
| `capturePhoto` / `deletePhoto`, their properties, `photo` and `error` objects, callbacks | DSL | What the app asks for and how it reacts is app logic: which camera, which crop, where the reference goes, what happens on refusal |
| Reference format `photo://<id>` and that an `image` `url` accepts it | DSL | The bundle stores and passes references, so their shape is part of the contract; reusing `url` keeps every image style and template working, and older engines draw an empty image instead of failing |
| Camera and library UI, permission prompts, the chooser | SDK | System UI and the platform permission model differ per platform and must look native; the DSL only sees the result |
| Downscale, crop, JPEG encode, metadata stripping | Both | The DSL sets the numbers (`maxDimension`, `aspectRatio`, `quality`) with safe defaults; the SDK does the image work with platform codecs |
| File storage, id generation, resolving a reference to pixels | SDK | Paths and storage APIs are per platform and must stay hidden so bundles stay portable |
| Cleanup at launch, deletion through `clearPersistedData` | SDK | Lifecycle of device files; follows from the persisted-variable rules the DSL already has |
| Usage strings (`NSCameraUsageDescription`) | Host | Apple reads them from the host app's `Info.plist`; the engine cannot supply them |

## Versioning

`capturePhoto`, `deletePhoto` and photo references in `image` arrive with release
train **0.7.2** on iOS, Android and the web renderer. `DSL_VERSION` stays `1.1`: features
are tracked by release (see [VERSIONING](../VERSIONING.md)). What older engines do
(checked in their code):

| Engine | `capturePhoto` / `deletePhoto` | `image` with a `photo://` url |
|--------|--------------------------------|-------------------------------|
| iOS and Android 0.7.0 and 0.7.1 | Decoded as an [unknown action type](actions.md#unknown-action-types): one `Unknown action type … skipped` diagnostic, the rest of the list runs. A capture button does nothing | The value has `://`, so it is tried as a remote URL: the host data source has no such asset, the URL load fails, the image draws nothing (its background shows) |
| iOS and Android before 0.7.0 | The screen fails to decode | As 0.7.0 |
| Web renderer before 0.7.2 | Skipped (it has always skipped unknown types) | Not an `http(s)` URL or bundle asset: nothing is drawn |

Ship screens that capture only to hosts on 0.7.2 or later. Screens that only show
photos are safe on 0.7.0 and 0.7.1 and degrade to empty images.
