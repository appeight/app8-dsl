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
| `properties.style` | string | `automatic` | `automatic`, `light` or `dark`: the look of the capsule and the default dot colors. `light`: a light capsule with dark dots; `dark`: a dark capsule with light dots; `automatic` follows the screen's appearance. Unknown values read as `automatic`. See [Light and dark](#light-and-dark). Since 0.7.16 |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | | Hide component; see [Visibility](../components.md#visibility) |

> **Binding direction**: `bindVariable` is **write-on-tap** — when the user taps a dot the new index is written to the variable. To drive the dots from elsewhere (e.g. a scrolling carousel), bind `currentPage` to the same variable with `"{{...}}"`.

## Style: PageControlStyle

| Property | Type | Description |
|----------|------|-------------|
| `pageIndicatorTintColor` | Color | Inactive dot color |
| `currentPageIndicatorTintColor` | Color | Active dot color |
| `material` | Material | Background |
| `alpha` | number | Opacity (0.0–1.0) |
| `contentMode` | ContentMode | Content alignment |

> **Media capsule (all renderers)**: the dots sit on a capsule (26 pt tall, `pages × 16 + 10` wide, 7 pt dots 9 pt apart) so they read on any photo. Its look follows `properties.style` (see [Light and dark](#light-and-dark)). iOS and the web renderer blur what is behind it; Android, which has no backdrop blur there, uses a slightly more opaque capsule. `pageIndicatorTintColor` and `currentPageIndicatorTintColor` color the dots when set (a hex or a color expression) and win over the style's dot colors; unset or invalid, the dots take the style's color, the current one solid and the others at half opacity. Pick tints that contrast with the capsule: light tints on `dark`, dark tints on `light`. iOS applies the tints since 0.6.0 (0.5.4 ignored them); Android draws the capsule from the release after 0.6.3.

## Light and dark

`properties.style` (since 0.7.16) sets the capsule and the default dot colors:

| Value | Capsule | Dots (unless tinted) |
|-------|---------|----------------------|
| `automatic` (default) | `light` on a screen that renders light, `dark` on a screen that renders dark | as the resolved look |
| `light` | Light: iOS `systemUltraThinMaterialLight` blur under a 40 % white wash; web (iOS) 58 % white with backdrop blur; Android 72 % white | Black, others black at 50 % |
| `dark` | Dark: iOS `systemUltraThinMaterialDark` blur under a 28 % black dim; web (iOS) 28 % black with backdrop blur; Android 38 % black | White, others white at 50 % |

**The `automatic` rule.** The control takes the appearance its screen renders in, the same appearance themed colors (`{"light": …, "dark": …}`) resolve against:

1. the screen's own `userInterfaceStyle` (see [Screen: Light and dark](screen.md#light-and-dark)); for a sheet or modal without one, its presenter's;
2. else the app's appearance: the host's `userInterfaceStyle` override, then the app's `defaultUserInterfaceStyle`;
3. else the device's light or dark setting.

Dark gives the `dark` look; light (or anything else) gives the `light` look. It is not read from the content behind the control: a page control over a dark photo on a light screen draws the light capsule. Pin `dark` (or `light`) for that case. Per platform: iOS reads the control's trait collection (`userInterfaceStyle`, which carries the screen's and the app's override) and follows it when it changes; Android reads the appearance of the screen's render environment, which themed colors resolve against too (the system's dark theme reaches it only through step 3); the web renderer reads the screen's appearance.

Engines before 0.7.16 ignore `style` and always draw the `dark` look. An app that sets `style` to `light` or `automatic` needs engine 0.7.16.

```json
{
  "type": "pageControl",
  "id": "galleryDots",
  "content": {
    "properties": {
      "numberOfPages": "{{photos.length}}",
      "currentPage": "{{photoIndex}}",
      "style": "dark"
    },
    "layout": { "centerX": 0, "bottom": 12 }
  }
}
```

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
