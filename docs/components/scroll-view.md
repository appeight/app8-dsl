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
| `properties.stretchesTopChild` | boolean | false | Vertical only. Pull-down at the top grows the hero (the first child) by the pull with its top on the top edge; only its background scales. See [Stretchy top](#stretchy-top) |
| `children` | Component[] | | Content components |
| `style` | ScrollViewStyle | | Styling |
| `layout` | Layout | | Position and size |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | | Hide component; see [Visibility](../components.md#visibility) |

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
| `never` | No automatic inset adjustment. Use when the DSL fully controls layout — e.g., full-screen scroll views with a hidden or transparent nav bar. A screen [`bottomBar`](screen.md#bottom-bar) still adds its height (and the bottom safe area under it) to the bottom inset of the screen's main vertical scroll view, since 0.7.11, so the last content can always scroll above the bar |
| `bottom` | Since 0.7.11. Only the bottom edge adjusts: the content starts at the very top of the scroll view, under the status bar and a transparent or hidden navigation bar, and the bottom inset follows the safe area (tab bar, `bottomBar`, home indicator). Use it for full-bleed hero screens (product, profile cover, story). Engines up to 0.7.10 read it as `automatic` |

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

## Content size

The scroll view's children sit in a content view pinned to its content edges.
Vertical content is as wide as the scroll view and as tall as its children
reach; horizontal content is as tall as the scroll view and as **wide as its
children reach**: a horizontal `stackView` pinned leading and trailing (with
insets as constants) takes its width from its arranged views, and no view is
stretched to fill a guessed width, the last one included. A row shorter than
the scroll view leaves the rest empty. Since 0.7.9 the web renderer does the
same as iOS and Android (it stretched the last arranged view before).

```json
{
  "type": "scrollView",
  "content": {
    "properties": { "direction": "horizontal", "showsIndicator": false },
    "layout": { "height": 36, "constraints": [ … ] },
    "children": [{
      "type": "stackView",
      "content": {
        "properties": { "axis": "horizontal", "spacing": 8 },
        "layout": { "constraints": [
          { "type": "leading", "target": "superview", "constant": 16 },
          { "type": "trailing", "target": "superview", "constant": -16 },
          { "type": "top", "target": "superview" },
          { "type": "bottom", "target": "superview" }
        ] },
        "children": [ "…chips: a view with a label pinned 14 pt inside…" ]
      }
    }]
  }
}
```

For a data-driven row, a horizontal `collection` with `itemWidth: "auto"` does
the same ([collections](../collections.md#items-sized-to-content)).

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
content is pulled down at the top, the **hero** grows to fill the pulled
distance. Content below moves down with the pull as usual. Use it for a hero
image, a cover, a video or an image carousel at the top of a home, product,
profile or story screen.

The hero is the scroll view's first child; when that child is a container
(a vertical `stackView`, or a `view` whose first child is a container pinned
to its top), the engine descends to its first child, then repeats, so the
usual `scrollView > stackView > heroBox` tree stretches the hero, not the
whole content. A leaf pinned to a view's top (an image, a video, a pager) is
that view's background, not its hero, so the descent stops at the view.
Since 0.7.11.

### What grows and what scales

At a pull of `d` points, the hero's frame grows taller by `d`: its top stays
on the scroll view's top edge and its bottom moves down with the content.

- **The background scales.** Only the hero's background scales to cover the
  taller frame, uniformly by `(h + d) / h` about the hero's bottom centre
  (`h` is its height at rest), so it keeps its aspect ratio and its sides
  grow past the screen edges (clipped by the scroll view), like Photos or App
  Store covers. The background is the hero's own `material` (fill, texture,
  gradient) and every child that covers the whole hero at rest: a photo, a
  video, a photo pager, a scrim. A pager keeps its paging after the pull ends.
- **Everything else is laid out again, never scaled.** Every other child
  (buttons, labels, a page control, badges, a text block) keeps its
  constraints inside the taller frame:
  - a child pinned to the top stays at the top;
  - a centred one re-centres;
  - one pinned to the bottom moves down with it at its own size. That also
    holds for a child pinned to both the top (or the safe area's top) and the
    bottom, such as a text block whose height comes from its content: it
    keeps its rest height and stays on the bottom.
- **The hero is all background** when it is not a `view` with children (an
  `image`, a `video`, a pager, a `stackView` with a height of its own). It
  then scales as a whole.

The hero keeps its rest height for the length of the pull, so a hero whose
height comes from its content (`height >= width` plus children pinned to the
safe area) still grows. Before 0.7.14 such a hero shrank as fast as it was
pulled on iOS: the safe area stays fixed on screen inside a scroll view. The
content below then never moved, as if the pull did nothing.

| Platform | Behavior |
|----------|----------|
| iOS | In `scrollViewDidScroll`, with `contentOffset.y < -adjustedContentInset.top`: the hero's height is held at its rest value, its content view's top moves up by `d` (its children are laid out again), and its material and covering children get the scale transform above. The scroll view must bounce (`bounces` true, the default); it does with any `contentInsetAdjustment` |
| Android | The same rule, driven by the overscroll of the pull at the top (the system stretch overscroll is turned off for this scroll view) |
| Web | The same rule, driven by the rubber-banded pull (iOS mode) or the overscroll (Android mode) |

Before 0.7.14 the whole hero scaled, its buttons and labels included. Before
0.7.11 iOS moved the first child's top and height constraints instead (a
first child that was a stack moved with the pull and nothing grew), and the
web renderer scaled the whole content.

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
