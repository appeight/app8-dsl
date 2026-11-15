# ScrollView

Scrollable container.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.direction` | Direction | `vertical` | Scroll direction |
| `properties.showsIndicator` | boolean | true | Show scroll indicator |
| `properties.outputVariable` | string | | Variable to write scroll offset to (0 at rest, positive when scrolled) |
| `properties.contentInsetAdjustment` | ContentInsetAdjustment | `automatic` | How iOS adjusts content insets for safe areas |
| `properties.contentInset` | EdgeInsets | | Explicit padding around the scroll content |
| `properties.bounces` | boolean | true | Whether the scroll view bounces past its content edges. A vertical scroll view bounces even when its content is shorter than the viewport (see [Bounce](#bounce)) |
| `properties.pagingEnabled` | boolean | false | Snap scrolling to multiples of the scroll view's bounds |
| `properties.keyboardDismissMode` | KeyboardDismissMode | `none` | How an on-screen keyboard is dismissed while scrolling |
| `properties.decelerationRate` | DecelerationRate | `normal` | Deceleration rate after a scroll gesture ends |
| `properties.autoScroll` | AutoScroll | | Continuous auto-scroll / marquee — see [Auto-scroll](#auto-scroll) |
| `properties.minimumZoomScale` | number | 1 | Smallest pinch zoom. See [Zoom](#zoom) |
| `properties.maximumZoomScale` | number | 1 | Largest pinch zoom. Above 1 turns zoom on |
| `properties.doubleTapZoom` | boolean | true when zoom is on | Double tap zooms to the tap point (2.5× or `maximumZoomScale`, whichever is smaller); double tap again zooms out |
| `properties.stretchesTopChild` | boolean | false | Vertical only. Pull-down at the top keeps the first child pinned to the top edge and grows its height by the pull distance. See [Stretchy top](#stretchy-top) |
| `children` | Component[] | | Content components |
| `style` | ScrollViewStyle | | Styling |
| `layout` | Layout | | Position and size |
| `properties.isHidden` | boolean/expression | | Hide component; see [Visibility](../components.md#visibility) |

## Direction Values

`vertical`, `horizontal`

## KeyboardDismissMode Values

| Value | Description |
|-------|-------------|
| `none` | Default. The keyboard is not dismissed by scrolling. |
| `onDrag` | The keyboard is dismissed when a drag begins. |
| `interactive` | The keyboard follows the drag, and can be dismissed interactively. |

## DecelerationRate Values

`normal` (default), `fast`

## ContentInsetAdjustment Values

| Value | Description |
|-------|-------------|
| `automatic` | Default. iOS adjusts content insets for safe areas (nav bar, tab bar, etc.). Matches UIKit default. |
| `never` | No automatic inset adjustment. Use when the DSL fully controls layout — e.g., full-screen scroll views with a hidden or transparent nav bar. |

> **Note:** Use `never` for screens with `navigationBar.hidden: true` and `ignoresSafeArea: true` where the content is intended to fill the full screen (e.g., a photo/hero scroll).
> Without `never`, the second-visit nav bar transition can cause a visible content jump.

## Bounce

Every vertically scrollable screen bounces: a drag past either edge stretches and springs back, also when the content fits the viewport (a short account or settings screen). Only `bounces: false` turns it off. Vertical `collection`s with scrolling enabled follow the same rule.

| Platform | Behavior |
|----------|----------|
| iOS | `bounces` and `alwaysBounceVertical` both `true` (vertical); `UICollectionView` the same |
| Android | Stretch overscroll on every vertical scroller (the content is always scrollable by its overscroll, also when it fits) |
| Web | Rubber band (iOS mode) or stretch (Android mode) past both edges, also when the content fits |

A screen whose children are placed directly on the screen does not scroll at all. Put a screen's content in a vertical `scrollView` (or a `collection`) whenever it could be taller than the smallest device, or should feel scrollable.

## outputVariable

When set, the variable receives the current scroll offset as a number:
- `0` at the natural resting position (top for vertical, left for horizontal)
- Positive when scrolled — e.g., `120` means 120pt scrolled from the top

Use this to drive animations (parallax, sticky headers, fading nav bars, etc.) via expressions.

## Auto-scroll

`autoScroll` drives the content offset every frame for marquee/ticker effects (scrolling banners, "now playing" strips, logo reels). Pair it with `direction: "horizontal"` for a classic marquee.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `speed` | number | | Points per second along the scroll axis. Positive scrolls toward the trailing edge (right/down); negative reverses |
| `infinite` | boolean | `true` | Duplicate the content so the loop wraps seamlessly. `false` = one-shot, stops at the trailing edge |
| `loopGap` | number | `0` | Gap (points) inserted between the original content and its duplicate — match your item spacing so the wrap looks even |

```json
{
  "type": "scrollView",
  "content": {
    "properties": {
      "direction": "horizontal",
      "showsIndicator": false,
      "pagingEnabled": true,
      "bounces": false,
      "autoScroll": { "speed": 30, "infinite": true, "loopGap": 30 }
    },
    "children": []
  }
}
```

## Zoom

With `maximumZoomScale` above 1 the scroll view zooms its content with a pinch,
like Photos. Put one child inside (usually an `image` that fills the scroll view).
The zoomed content stays centered while smaller than the frame.

| Platform | Native behavior |
|----------|-----------------|
| iOS | `UIScrollView` `minimumZoomScale` / `maximumZoomScale`, `viewForZooming` returns the content view, bounce past limits (`bouncesZoom`). Double tap: `zoom(to:animated:)` |
| Android | `me.saket.telephoto` `Modifier.zoomable(rememberZoomableState(ZoomSpec(maxZoomFactor)))` with double-tap zoom. Over-zoom springs back |

A zoomed scroll view inside a horizontal paging collection keeps horizontal pans
while zoomed in. At a content edge (or at scale 1) the pan passes to the pager,
so a swipe changes the page.

`zoomScale` is written to `outputVariable` as `{ offset, zoomScale }` only when
zoom is on. Without zoom `outputVariable` keeps the plain offset number.

## Stretchy top

`stretchesTopChild: true` gives the standard iOS stretchy header: when the
content is pulled down at the top, the first child stays pinned to the scroll
view's top edge and its height grows by the pull distance. Content below moves
down with the pull as usual. Use it for a hero image or an image carousel at the
top of a product screen. The child's width does not change; images with
`scaleAspectFill` zoom in as they grow.

| Platform | Behavior |
|----------|----------|
| iOS | In `scrollViewDidScroll`, with `contentOffset.y < -adjustedContentInset.top`, the first child's top moves to the offset and its height grows by the overscroll. A horizontal collection inside re-lays out its items at the new height |
| Android | No custom effect. The system stretch overscroll (`OverscrollEffect`, Android 12+) stretches the whole content. This matches the platform convention |

## Style: ScrollViewStyle

| Property | Type | Description |
|----------|------|-------------|
| `material` | Material | Background material |
| `alpha` | number | Opacity (0.0–1.0) |

## Example — basic vertical scroll

```json
{
  "type": "scrollView",
  "content": {
    "properties": {
      "direction": "vertical",
      "showsIndicator": true
    },
    "layout": {
      "constraints": [
        { "type": "top", "target": "superview" },
        { "type": "leading", "target": "superview" },
        { "type": "trailing", "target": "superview" },
        { "type": "bottom", "target": "superview" }
      ]
    },
    "children": []
  }
}
```

## Example — scroll with outputVariable (parallax / sticky header)

```json
{
  "variables": {
    "scrollOffset": { "type": "number", "initialValue": 0 }
  },
  "children": [
    {
      "type": "scrollView",
      "content": {
        "properties": {
          "direction": "vertical",
          "outputVariable": "scrollOffset"
        },
        "layout": { ... },
        "children": [...]
      }
    },
    {
      "type": "view",
      "content": {
        "style": { "alpha": "{{1 - scrollOffset / 100}}" }
      }
    }
  ]
}
```

## Example — zoomable image page

<!-- @dsl-type: Component -->
```json
{
  "type": "scrollView",
  "id": "zoomPage",
  "content": {
    "properties": { "minimumZoomScale": 1, "maximumZoomScale": 4, "showsIndicator": false, "contentInsetAdjustment": "never" },
    "children": [
      {
        "type": "image",
        "id": "zoomImage",
        "content": {
          "properties": { "type": "remoteAsset", "url": "{{item.url}}" },
          "style": { "contentMode": "scaleAspectFit" },
          "layout": {
            "constraints": [
              { "type": "top", "target": "superview" },
              { "type": "leading", "target": "superview" },
              { "type": "trailing", "target": "superview" },
              { "type": "bottom", "target": "superview" },
              { "type": "width", "target": "superview" },
              { "type": "height", "target": "superview" }
            ]
          }
        }
      }
    ]
  }
}
```

## Example — scroll under opaque navigation bar

```json
{
  "type": "scrollView",
  "content": {
    "properties": {
      "direction": "vertical",
      "contentInsetAdjustment": "automatic"
    },
    "layout": { ... },
    "children": [...]
  }
}
```
