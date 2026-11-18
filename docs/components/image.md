# Image

Image display component.

## Content Properties

| Property | Type | Description |
|----------|------|-------------|
| `properties.url` | string | Remote image URL. Without `type`, the image is a `remoteAsset` |
| `properties.asset` | string | Local asset name. Without `type`, the image is a `localAsset` |
| `properties.name` | string | Asset name (or URL) for an explicit `type`. Without `type`, the same as `asset` |
| `properties.type` | string | Optional: `"remoteAsset"` or `"localAsset"`. Inferred when absent (see [Image source](#image-source)) |
| `style` | ImageStyle | Image styling |
| `layout` | Layout | Position and size |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | Hide component; see [Visibility](../components.md#visibility) |

## Image source

`type` is optional. Without it the source comes from the first property present:

| Properties | Image |
|------------|-------|
| `url` | `remoteAsset` from `url` |
| `asset` | `localAsset` named `asset` |
| `name` | `localAsset` named `name` (an `http(s)` value is loaded as a URL) |
| `type: "remoteAsset"` + `url` or `name` | remote, from that value; a value that is not an absolute URL is a file in the bundle's assets |
| `type: "localAsset"` + `name` or `asset` | local asset |

```json
{ "type": "image", "content": { "properties": { "url": "https://example.com/hero.jpg" } } }
```

An image with none of these draws nothing (its background and size still apply).

## Style: ImageStyle

| Property | Type | Description |
|----------|------|-------------|
| `contentMode` | ContentMode | How image fills bounds |
| `tintColor` | Color | Tint for template images |
| `renderingMode` | RenderingMode | Image rendering mode |
| `corner` | Corner | Corner radius |
| `material` | Material | Background material |
| `alpha` | number | Opacity |
| `blendMode` | BlendMode | How the view composites with content beneath it (`normal`, `multiply`, `screen`, `overlay`, `darken`, `lighten`, `colorDodge`, `colorBurn`, `softLight`, `hardLight`, `difference`, `exclusion`, `hue`, `saturation`, `color`, `luminosity`). Same as Figma / CSS `mix-blend-mode`. |

## ContentMode Values

| Value | Description |
|-------|-------------|
| `scaleToFill` | Stretch to fill |
| `scaleAspectFit` | Fit maintaining aspect ratio |
| `scaleAspectFill` | Fill maintaining aspect ratio |
| `center` | Center without scaling |

## RenderingMode Values

| Value | Description |
|-------|-------------|
| `automatic` | System decides |
| `alwaysTemplate` | Render as template (tintable) |
| `alwaysOriginal` | Render original colors |

## Example

<!-- @dsl-type: Component -->
```json
{
  "type": "image",
  "content": {
    "properties": {
      "url": "https://example.com/photo.jpg"
    },
    "style": {
      "contentMode": "scaleAspectFill",
      "corner": { "radius": 8 }
    },
    "layout": {
      "width": 100,
      "height": 100
    }
  }
}
```
