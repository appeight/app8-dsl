# PageControl

A row of page-indicator dots (`UIPageControl`). Shows the current position in a paged sequence and lets the user tap to jump.

Commonly paired with a horizontally-paged [carousel collection](../collections.md) or [scrollView](scroll-view.md) — bind both to the same index variable so the dots and the content stay in sync.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.numberOfPages` | number/expression | `0` | Total page count. Accepts an expression, e.g. `"{{photos.length}}"` |
| `properties.currentPage` | number/expression | `0` | Active page index (0-based). Accepts an expression |
| `properties.bindVariable` | string | | Variable name the tapped page index is written to (no `{{}}`) |
| `properties.hidesForSinglePage` | boolean | `true` | Hide the control when there is only one page |
| `properties.isHidden` | boolean/expression | | Hide component; see [Visibility](../components.md#visibility) |

> **Binding direction**: `bindVariable` is **write-on-tap** — when the user taps a dot the new index is written to the variable. To drive the dots from elsewhere (e.g. a scrolling carousel), bind `currentPage` to the same variable with `"{{...}}"`.

## Style: PageControlStyle

| Property | Type | Description |
|----------|------|-------------|
| `pageIndicatorTintColor` | Color | Inactive dot color |
| `currentPageIndicatorTintColor` | Color | Active dot color |
| `material` | Material | Background |
| `alpha` | number | Opacity (0.0–1.0) |
| `contentMode` | ContentMode | Content alignment |

> **iOS**: the iOS renderer draws the media capsule (dots on a dark blurred capsule, 26 pt tall, so they read on any photo; same look as the web renderer). Since 0.6.0 it applies `pageIndicatorTintColor` and `currentPageIndicatorTintColor` to the dots when set (a hex or a color expression); unset or invalid, the dots are white, the current one solid and the others at half opacity. 0.5.4 ignored both colors.

## Example

```json
{
  "type": "pageControl",
  "id": "photoDots",
  "content": {
    "properties": {
      "numberOfPages": "{{photos.length}}",
      "currentPage": "{{currentPhotoIndex}}",
      "bindVariable": "currentPhotoIndex"
    },
    "style": {
      "pageIndicatorTintColor": "#D1D1D6",
      "currentPageIndicatorTintColor": "#007AFF"
    },
    "layout": { "centerX": 0, "bottom": 16 }
  }
}
```

## See Also

- [Collections](../collections.md) — carousel layouts that pair with a page control
- [ScrollView](scroll-view.md) — paged scrolling
