# Collections

Collections render dynamic lists, grids, and carousels from data.

> For layout choice, inset values, header patterns, and common mistakes, see [collections-best-practices.md](collections-best-practices.md).

## Basic Structure

```json
{
  "type": "collection",
  "content": {
    "properties": {
      "data": "{{items}}"
    },
    "layout": {
      "type": "vertical",
      "itemSpacing": 8
    },
    "template": { }
  }
}
```

---

## Data Sources

| Property | Type | Description |
|----------|------|-------------|
| `data` | expression | Dynamic data from a variable (e.g., `"{{users}}"`) |
| `sectionDefinitions` | array | Multiple independent data sources, one per section |

These two are **mutually exclusive**. Precedence: `sectionDefinitions` > `data`.

Use `data` when the array comes from a variable (use a variable with `initialValue` for static data). Use `sectionDefinitions` when each section has a completely independent data source (see [Multiple Independent Sections](#multiple-independent-sections)).

For grouping a **single** data source into sections, use `groupBy` instead (see [Sections](#sections)).

### Dynamic Data

```json
{
  "properties": {
    "data": "{{users}}"
  }
}
```

---

## Layout Types

### Vertical List

Standard scrolling list.

```json
{
  "layout": {
    "type": "vertical",
    "itemSpacing": 12,
    "separatorStyle": "inset"
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | string | | `"vertical"` |
| `itemSpacing` | number | `0` | Space between items |
| `separatorStyle` | string | `"none"` | `"none"`, `"full"`, `"inset"` |
| `estimatedItemHeight` | number | | Hint for self-sizing items; improves layout performance |
| `itemHeight` | number / `"fill"` | | Fixed item height (items self-size without it). `"fill"`: each item is as tall as the collection's frame minus vertical insets (a full-screen feed) |
| `pagingStyle` | string | `"continuous"` | `"continuous"` (free scroll) or `"paging"` (page by item height plus `itemSpacing`; by the frame for self-sizing items) |
| `currentPageVariable` | string | | With `pagingStyle: "paging"`: the current page index, two-way, exactly as for [horizontal collections](#horizontal-carousel) |
| `contentInsets` | object | | Padding around content: `top`, `left`, `bottom`, `right` |
| `showsScrollIndicator` | boolean | `true` | Show or hide the vertical scroll indicator |

#### Vertical paging (a full-screen feed)

One item per screen, swipe up for the next:

```json
{
  "type": "collection",
  "id": "feed",
  "content": {
    "properties": {
      "data": "{{posts}}",
      "layout": {
        "type": "vertical",
        "pagingStyle": "paging",
        "itemHeight": "fill",
        "currentPageVariable": "feedPage",
        "showsScrollIndicator": false
      }
    },
    "template": { "type": "view", "content": { "children": [] } }
  }
}
```

- Items come from `data` (or `sectionDefinitions` / `groupBy`) like any collection;
  templates and item variables are unchanged. Pages run through all items in order.
- A swipe turns one page; a fast flick also turns exactly one page, never several
  (feed behaviour). A slow drag past half a page turns it; less springs back. On the
  web renderer a mouse-wheel notch turns one page, and a trackpad swipe turns at most one.
- A vertical collection with `pagingStyle: "paging"` or `itemHeight: "fill"` adds **no
  automatic safe-area insets**: the page is the collection's own frame. Run the
  collection edge to edge (pin it to `superview`, under translucent bars) and keep text
  and buttons inside the template clear of the bars with `safeArea` anchors.
- `currentPageVariable` updates when a swipe settles on another page, and writing the
  variable scrolls to that page (animated while on screen).
- Applies to a plain vertical list. With `sectionLayouts`, `defaultSectionLayout`,
  `sectionHeaders` or `swipeActions`, `pagingStyle` is ignored and the list scrolls freely.
- An engine older than this feature ignores `pagingStyle` and `itemHeight` on a vertical
  list: the feed scrolls freely with self-sizing items.

### Horizontal Carousel

Horizontally scrolling list.

```json
{
  "layout": {
    "type": "horizontal",
    "itemSpacing": 16,
    "itemWidth": 280,
    "itemHeight": 200,
    "pagingStyle": "paging"
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | string | | `"horizontal"` |
| `itemSpacing` | number | `0` | Space between items |
| `itemWidth` | number / `"fill"` | | Fixed item width. `"fill"`: the collection's width minus horizontal insets |
| `itemHeight` | number / `"fill"` | | Fixed item height. `"fill"`: each item is as tall as the collection's frame minus vertical insets (a full-screen pager) |
| `rows` | number | `1` | Number of rows in a multi-row horizontal carousel |
| `pagingStyle` | string | `"continuous"` | `"continuous"` (free scroll), `"paging"` (page by item width), `"pagingCentered"` (page with centered item) |
| `currentPageVariable` | string | | Plain variable name for the current page index. Two-way: paging writes it, and a write from elsewhere (another screen, an action) scrolls the collection to that page without animation while it is off screen, animated while visible. Can be an app variable, so a full-screen gallery and the product carousel stay on the same page |
| `estimatedItemHeight` | number | | Hint for self-sizing items |
| `contentInsets` | object | | Padding around content: `top`, `left`, `bottom`, `right` |
| `showsScrollIndicator` | boolean | `false` | Show the horizontal scroll indicator. Off by default for every horizontal collection (carousels, chip rows, tab-like rows) and for horizontal sections in `sectionLayouts` / `defaultSectionLayout`; set `true` to show it. Android draws no scroll indicators ([platforms](platforms.md)) |

> **Legacy**: `snapToItem: true` and `pagingEnabled: true` are accepted but `pagingStyle` is preferred.

### Grid

```json
{
  "layout": {
    "type": "grid",
    "columns": 3,
    "itemSpacing": 8,
    "lineSpacing": 8,
    "aspectRatio": 1.0
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | string | | `"grid"` |
| `columns` | number | | Number of columns |
| `itemSpacing` | number | `0` | Horizontal space between items |
| `lineSpacing` | number | `0` | Vertical space between rows |
| `aspectRatio` | number | | Item aspect ratio (width ÷ height) |
| `itemHeight` | number | | Fixed item height (alternative to `aspectRatio`) |
| `estimatedItemHeight` | number | | Hint for self-sizing items |
| `contentInsets` | object | | Padding around content: `top`, `left`, `bottom`, `right` |
| `showsScrollIndicator` | boolean | `true` | Show or hide the scroll indicator |

#### Self-sizing grid rows

Without `itemHeight` or `aspectRatio`, grid items size to their content (`estimatedItemHeight` is the first guess). Each row is as tall as its tallest item, and every item in the row stretches to that height, so neighbours line up. To keep a footer (a button, a price) on the bottom edge, pin it to the bottom and give the content above it a `>=` gap:

<!-- @dsl-skip: constraint fragment -->
```json
{ "type": "top", "target": "cardInfo", "attribute": "bottom", "constant": 14, "op": ">=" }
```

An item's natural height is the smallest one its constraints allow: a `>=` gap is measured at its minimum, never stretched to `estimatedItemHeight` or to a height the item had before. There is no fixed card height to keep in sync with the content.

Renderers lay out items near the viewport first and the rest as they come into view, as `UICollectionView` does with estimated sizes.

Scrolling a self-sizing grid tracks the finger 1:1:

- A row's height is final on its first layout: its other items are measured right then, not in a later pass.
- An item's natural height is remembered by item identity (template and item data, at the column width), not by position, so a reused cell or a row scrolled back into view takes the height measured the first time. Rows above the viewport never change height while the user scrolls back up, so the offset never shifts under the finger and nothing jumps after deceleration.
- Only an item whose content changed is measured again, and only its row relays out. Scrolling over measured items, and the overscroll past either end, relay out nothing.
- A cell shown for another item (native cell reuse) is measured with that item's values: bound text, `isHidden`, dimensions and the template's computed variables all follow the new item before the cell is measured or drawn.

| Platform | Row height |
|----------|------------|
| iOS | Horizontal group with `.estimated` item and group heights; each cell is measured from a compressed height (`UIView.layoutFittingCompressedSize`) and reports its row's tallest natural height (the group alone leaves shorter items short) |
| Android | Row measured at the tallest item, then every item measured again at that height |
| Web | Same as Android |

---

## Sizing to Content

A vertical or grid collection that does **not scroll itself** is as tall as its
content. Its items self-size from their constraints (no `itemHeight` needed), and
the collection's height is the sum of its rows, spacing, section headers and
footers, and vertical `contentInsets`. This is how a short list or grid sits inside
a scrolling page with other content above and below it.

A collection does not scroll itself when either holds:

- `layout.scrollEnabled` is `false`, or
- it is inside a vertical [`scrollView`](components/scroll-view.md) (directly or
  through stacks and views) and has no height of its own (no `layout.height`, no
  `top` + `bottom` pair, no height constraint). The outer scroll view scrolls
  instead.

<!-- @dsl-type: Component -->
```json
{
  "type": "scrollView",
  "content": {
    "layout": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 },
    "children": [
      {
        "type": "stackView",
        "content": {
          "properties": { "axis": "vertical", "spacing": 24 },
          "layout": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 },
          "children": [
            { "type": "label", "content": { "properties": { "text": "Recently viewed" } } },
            {
              "type": "collection",
              "content": {
                "properties": { "data": "{{recentlyViewed}}" },
                "layout": { "type": "grid", "columns": 2, "itemSpacing": 12, "lineSpacing": 12, "scrollEnabled": false },
                "template": {
                  "type": "label",
                  "content": {
                    "properties": { "text": "{{item.title}}", "numberOfLines": 0 },
                    "layout": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 }
                  }
                }
              }
            }
          ]
        }
      }
    ]
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `layout.scrollEnabled` | boolean | `true` | `false`: the collection never scrolls and sizes its height to its content |

Rules:

- The height follows the data: adding, removing or resizing items changes the
  collection's height, and the views around it move.
- Every item is laid out (no lazy loading by viewport), so keep these collections
  short: tens of items, not hundreds. A long list should be the scrolling container
  itself.
- An explicit height (`layout.height` or `top` + `bottom`) wins: the collection keeps
  that height, and scrolls inside it unless `scrollEnabled` is `false`.
- `itemHeight`, `aspectRatio` and self-sizing items all work; `estimatedItemHeight`
  is only a first guess.
- Horizontal collections keep scrolling sideways and are sized by `itemHeight` or
  their layout as before.

---

## Mixed Layouts

Use `defaultSectionLayout` or `sectionLayouts` inside `properties` to give each section its own layout (orthogonal scrolling). This enables, for example, a vertical list where each section scrolls horizontally.

`defaultSectionLayout` sets the fallback layout applied to all sections. `sectionLayouts` overrides per section, keyed by the `groupBy` value or `SectionDefinition.key`.

```json
{
  "properties": {
    "data": "{{feed}}",
    "groupBy": "item.category",
    "defaultSectionLayout": {
      "type": "horizontal",
      "itemWidth": 160,
      "itemHeight": 200,
      "itemSpacing": 12,
      "contentInsets": { "left": 16, "right": 16 }
    },
    "sectionLayouts": {
      "featured": {
        "type": "horizontal",
        "itemWidth": 320,
        "itemHeight": 240,
        "pagingStyle": "paging"
      }
    }
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `defaultSectionLayout` | Layout | Fallback layout applied to all sections (overridden per-section by `sectionLayouts`) |
| `sectionLayouts` | object | Per-section layout overrides keyed by `groupBy` value or `SectionDefinition.key` |

---

## Style

The `style` key controls the visual appearance of the collection container.

```json
{
  "style": {
    "backgroundColor": "#F2F2F7",
    "separatorColor": "#E5E5EA",
    "separatorInset": 16
  }
}
```

| Property | Type | Description |
|----------|------|-------------|
| `material` | array | Material/fill layers (same format as view `material`) |
| `alpha` | number | Opacity of the collection view |
| `backgroundColor` | string | Hex background color |
| `separatorColor` | string | Hex color for separators (used with `separatorStyle`) |
| `separatorInset` | number | Leading inset for `"inset"` separators |

---

## Templates

### Single Template

All items use the same inline template:

```json
{
  "template": {
    "type": "view",
    "content": {
      "style": {
        "material": [
          { "fill": { "solid": "#FFFFFF" } },
          { "corner": { "radius": 8 } }
        ]
      },
      "layout": { "height": 60 },
      "children": [
        {
          "type": "label",
          "content": {
            "properties": { "text": "{{item.name}}" },
            "layout": { "leading": 16, "centerY": 0 }
          }
        }
      ]
    }
  }
}
```

### Template Reference

Reference an app-level template by name via `properties.templateName`:

```json
{
  "properties": {
    "templateName": "UserCard"
  }
}
```

### Heterogeneous Templates

Use `templateKey` and `templates` to render different templates per item type. `templateKey` is an item property path; `templates` maps each value to an inline component or a named template string.

```json
{
  "properties": {
    "templateKey": "item.type"
  },
  "templates": {
    "post": {
      "type": "view",
      "content": { }
    },
    "ad": "AdBanner",
    "product": "ProductTile"
  }
}
```

> **Boolean keys**: When `templateKey` points to a boolean property, the value is coerced to the string `"true"` or `"false"`. Use those as your template keys:
> ```json
> { "templateKey": "item.isFeatured", "templates": { "true": { ... }, "false": { ... } } }
> ```

---

## Item Variables

Inside templates, these variables are automatically available:

| Variable | Description |
|----------|-------------|
| `{{item}}` | Current item data |
| `{{item.$index}}` | 0-based index of the item |
| `{{item.property}}` | Any property on the item |
| `{{$parent}}` | Parent scope (screen-level variables) |
| `{{$parent.$parent}}` | Grandparent scope |

### Accessing Screen Variables

```json
"text": "{{$parent.currency}}{{item.price}}"
"hidden": "{{!$parent.showPrices}}"
```

---

## Sections

Group items by a property and render section headers.

```json
{
  "properties": {
    "groupBy": "item.category",
    "stickyHeaders": true
  },
  "defaultSectionHeader": {
    "type": "label",
    "content": {
      "properties": { "text": "{{section.key}}" },
      "style": {
        "text": { "fontSize": 14, "fontWeight": "semibold", "color": "#666666" }
      },
      "layout": { "leading": 16, "height": 32 }
    }
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `groupBy` | string | | Item property path to group by (e.g., `"item.category"`) |
| `stickyHeaders` | boolean | `false` | Pin section headers while scrolling |

**Header templates** (defined at the `content` level, not inside `properties`):

| Key | Description |
|-----|-------------|
| `defaultSectionHeader` | Single template applied as the default header for **all** sections |
| `sectionHeaders` | Map of templates keyed by section key — overrides `defaultSectionHeader` for specific sections |

If both are defined, `sectionHeaders[key]` takes precedence over `defaultSectionHeader` for any section whose key has a match.

Headers work with `groupBy` and with `sectionDefinitions`, in `vertical` and `grid` layouts:
each header spans the section's width (inside the left/right `contentInsets`) above its
items, and a grid starts a new row for each section. A sectioned product grid needs no
scroll view, stack or non-scrolling grids around it. Top-level `horizontal` collections do
not draw section headers.

### Section Variables

Inside `defaultSectionHeader` (or `sectionHeaders`) templates:

| Variable | Description |
|----------|-------------|
| `{{section.key}}` | The grouping value for this section |
| `{{section.items}}` | Items in this section |
| `{{section.$index}}` | 0-based section index |

---

## Multiple Independent Sections

Use `sectionDefinitions` when each section has its own completely independent data source (e.g., a profile header, a settings list, and a support list all from different variables).

**When to use `sectionDefinitions` vs `groupBy`:**
- `sectionDefinitions` — each section binds to a **different variable** (independent data sources)
- `groupBy` — all items come from a **single variable**, dynamically split into sections by a property value

```json
{
  "properties": {
    "sectionDefinitions": [
      { "key": "header",   "data": "{{profileData}}",   "templateName": "profileHeader" },
      { "key": "settings", "data": "{{settingsItems}}", "templateName": "settingsRow" },
      { "key": "support",  "data": "{{supportItems}}",  "templateName": "settingsRow" }
    ]
  }
}
```

Each entry in `sectionDefinitions`:

| Property | Type | Description |
|----------|------|-------------|
| `key` | string | Unique section key (used to match `sectionLayouts` and `sectionHeaders`) |
| `data` | expression | Variable expression for this section's data. The section rebuilds when any variable the expression reads changes, e.g. both `allProducts` and `wishlist` in `{{filter(allProducts, wishlist.includes(item.handle))}}`, and items leave the list when the array shrinks |
| `templateName` | string | Name of the registered template to use for items in this section |
| `templateKey` | string | Item property path for heterogeneous templates within this section |

---

## Empty / Loading / Error States

Provide component trees to display when the collection is empty, loading, or in an error state.

```json
{
  "emptyState": {
    "type": "view",
    "content": {
      "children": [
        {
          "type": "icon",
          "content": {
            "properties": { "name": "tray" },
            "style": { "tintColor": "#999999" }
          }
        },
        {
          "type": "label",
          "content": {
            "properties": { "text": "No items yet" }
          }
        }
      ]
    }
  },
  "loadingState": {
    "type": "view",
    "content": {
      "children": [
        {
          "type": "label",
          "content": { "properties": { "text": "Loading..." } }
        }
      ]
    }
  },
  "errorState": {
    "type": "view",
    "content": {
      "children": [
        {
          "type": "label",
          "content": { "properties": { "text": "Failed to load" } }
        },
        {
          "type": "button",
          "content": {
            "properties": { "text": "Retry" },
            "actions": {
              "tap": { "type": "executeFunction", "function": "retry" }
            }
          }
        }
      ]
    }
  }
}
```

---

## Selection

Enable item selection with single or multiple modes. The selected value (or array of values) is written back to a variable via `binding`.

### Single Selection

```json
{
  "properties": {
    "selection": {
      "mode": "single",
      "binding": "{{selectedId}}"
    }
  }
}
```

### Multiple Selection

```json
{
  "properties": {
    "selection": {
      "mode": "multiple",
      "binding": "{{selectedIds}}"
    }
  },
  "actions": {
    "onSelectionChange": {
      "type": "executeFunction",
      "function": "handleSelectionChange"
    }
  }
}
```

| Mode | Description |
|------|-------------|
| `none` | No selection (default) |
| `single` | One item selected at a time |
| `multiple` | Toggle items in/out of a set |

---

## Scroll Behavior

### Inverted

Flip the scroll direction so the latest content appears at the bottom. Useful for chat-style lists.

```json
{
  "properties": {
    "inverted": true
  }
}
```

### Scroll Offset Output

Write the current scroll offset to a variable. The value updates as the user scrolls.

```json
{
  "properties": {
    "scrollOffsetVariable": "scrollY"
  }
}
```

The value written is the vertical (or horizontal) content offset in points, adjusted for content insets.

---

## Actions

> Each trigger below also accepts an `analytics` binding alongside `actions:` for tracking — see [`analytics.md`](analytics.md) (Collection `onItemTap` example).

### Item Tap

```json
{
  "actions": {
    "onItemTap": {
      "type": "navigation",
      "nextScreen": "details",
      "params": { "itemId": "{{item.id}}" }
    }
  }
}
```

### Pull to Refresh

```json
{
  "properties": {
    "pullToRefresh": true
  },
  "actions": {
    "onRefresh": { "type": "executeFunction", "function": "refresh" }
  }
}
```

### Pagination

Trigger a load-more action when the user scrolls within `threshold` items of the end.

```json
{
  "properties": {
    "pagination": {
      "threshold": 5
    }
  },
  "actions": {
    "onLoadMore": { "type": "executeFunction", "function": "loadMore" }
  }
}
```

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `threshold` | number | `5` | Number of items from the end that triggers `onLoadMore` |

---

## Nested Collections

A collection inside a collection template. The inner collection's `data` binds to a property on the outer `{{item}}`.

```json
{
  "type": "collection",
  "content": {
    "properties": { "data": "{{sections}}" },
    "layout": { "type": "vertical", "itemSpacing": 24 },
    "template": {
      "type": "view",
      "content": {
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "{{item.title}}" },
              "style": { "text": { "fontSize": 20, "fontWeight": "bold" } },
              "layout": { "leading": 16, "top": 0 }
            }
          },
          {
            "type": "collection",
            "content": {
              "properties": { "data": "{{item.items}}" },
              "layout": {
                "type": "horizontal",
                "itemSpacing": 12,
                "itemWidth": 150,
                "itemHeight": 200
              },
              "template": {
                "type": "view",
                "content": {
                  "children": [
                    {
                      "type": "image",
                      "content": {
                        "properties": { "url": "{{item.imageUrl}}" },
                        "style": { "contentMode": "scaleAspectFill" },
                        "layout": { "leading": 0, "trailing": 0, "top": 0, "height": 150 }
                      }
                    },
                    {
                      "type": "label",
                      "content": {
                        "properties": { "text": "{{item.name}}" },
                        "layout": { "leading": 8, "trailing": 8, "top": 158 }
                      }
                    }
                  ]
                }
              }
            }
          }
        ]
      }
    }
  }
}
```

---

## Complete Examples

### Simple List

```json
{
  "type": "collection",
  "content": {
    "properties": { "data": "{{users}}" },
    "layout": {
      "type": "vertical",
      "itemSpacing": 1,
      "separatorStyle": "full"
    },
    "style": {
      "separatorColor": "#E5E5EA"
    },
    "template": {
      "type": "view",
      "content": {
        "style": {
          "material": [{ "fill": { "solid": "#FFFFFF" } }]
        },
        "layout": { "height": 60 },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "{{item.name}}" },
              "style": { "text": { "fontSize": 17 } },
              "layout": { "leading": 16, "centerY": 0 }
            }
          },
          {
            "type": "icon",
            "content": {
              "properties": { "name": "chevron.right" },
              "style": { "tintColor": "#C7C7CC" },
              "layout": { "trailing": 16, "centerY": 0 }
            }
          }
        ]
      }
    },
    "actions": {
      "onItemTap": {
        "type": "navigation",
        "nextScreen": "userDetail",
        "params": { "userId": "{{item.id}}" }
      }
    }
  }
}
```

### Photo Grid

```json
{
  "type": "collection",
  "content": {
    "properties": { "data": "{{photos}}" },
    "layout": {
      "type": "grid",
      "columns": 3,
      "itemSpacing": 2,
      "lineSpacing": 2,
      "aspectRatio": 1.0
    },
    "template": {
      "type": "image",
      "content": {
        "properties": { "url": "{{item.thumbnailUrl}}" },
        "style": { "contentMode": "scaleAspectFill" }
      }
    },
    "actions": {
      "onItemTap": {
        "type": "navigation",
        "nextScreen": "photoViewer",
        "params": { "photoId": "{{item.id}}" },
        "presentation": "fullScreen"
      }
    }
  }
}
```

### Paged Horizontal Carousel

```json
{
  "type": "collection",
  "content": {
    "properties": {
      "data": "{{slides}}",
      "scrollOffsetVariable": "carouselOffset"
    },
    "layout": {
      "type": "horizontal",
      "itemWidth": 320,
      "itemHeight": 200,
      "itemSpacing": 16,
      "pagingStyle": "pagingCentered",
      "currentPageVariable": "currentSlide",
      "contentInsets": { "left": 24, "right": 24 }
    },
    "template": {
      "type": "view",
      "content": {
        "style": {
          "material": [
            { "fill": { "solid": "#FFFFFF" } },
            { "corner": { "radius": 16 } }
          ]
        },
        "children": [
          {
            "type": "image",
            "content": {
              "properties": { "url": "{{item.imageUrl}}" },
              "style": { "contentMode": "scaleAspectFill" },
              "layout": { "leading": 0, "trailing": 0, "top": 0, "bottom": 0 }
            }
          }
        ]
      }
    }
  }
}
```

### Chat List (Inverted)

```json
{
  "type": "collection",
  "content": {
    "properties": {
      "data": "{{messages}}",
      "inverted": true
    },
    "layout": {
      "type": "vertical",
      "itemSpacing": 8,
      "contentInsets": { "top": 16, "bottom": 16, "left": 12, "right": 12 }
    },
    "template": {
      "type": "view",
      "content": {
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "{{item.text}}" },
              "style": { "text": { "fontSize": 15 } },
              "layout": { "leading": 12, "trailing": 12, "top": 8, "bottom": 8 }
            }
          }
        ]
      }
    }
  }
}
```

### Grouped List with Section Headers

```json
{
  "type": "collection",
  "content": {
    "properties": {
      "data": "{{contacts}}",
      "groupBy": "item.section",
      "stickyHeaders": true
    },
    "layout": {
      "type": "vertical",
      "itemSpacing": 0,
      "separatorStyle": "inset"
    },
    "defaultSectionHeader": {
      "type": "view",
      "content": {
        "style": {
          "backgroundColor": "#F2F2F7"
        },
        "layout": { "height": 28 },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "{{section.key}}" },
              "style": { "text": { "fontSize": 13, "fontWeight": "semibold", "color": "#6D6D72" } },
              "layout": { "leading": 16, "centerY": 0 }
            }
          }
        ]
      }
    },
    "template": {
      "type": "view",
      "content": {
        "style": { "material": [{ "fill": { "solid": "#FFFFFF" } }] },
        "layout": { "height": 56 },
        "children": [
          {
            "type": "label",
            "content": {
              "properties": { "text": "{{item.name}}" },
              "layout": { "leading": 16, "centerY": 0 }
            }
          }
        ]
      }
    },
    "actions": {
      "onItemTap": {
        "type": "navigation",
        "nextScreen": "contactDetail",
        "params": { "contactId": "{{item.id}}" }
      }
    }
  }
}
```
