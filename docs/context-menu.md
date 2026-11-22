# Context Menu

A long press on a component opens a **context menu**: a preview of the content
and a list of actions. This is the native "peek" pattern on iOS. It is set with
`content.contextMenu` on a `view`, `stackView`, `image` or `button`, including a
collection cell's root view.

```json
{
  "type": "view",
  "id": "productCard",
  "content": {
    "contextMenu": {
      "preview": { "component": { "templateId": "ProductQuickView" }, "width": 340 },
      "items": [
        { "id": "add", "title": "Add to bag", "icon": "bag", "actions": [ { "type": "incrementArrayItem", "variableName": "cart", "matchBy": "key", "value": { "key": "{{item.handle}}", "title": "{{item.title}}" } } ] },
        { "id": "wish", "title": "{{wishlist.includes(item.handle) ? 'Remove from wishlist' : 'Add to wishlist'}}", "icon": "{{wishlist.includes(item.handle) ? 'heart.fill' : 'heart'}}", "actions": [ { "type": "toggleArrayValue", "variableName": "wishlist", "value": "{{item.handle}}" } ] },
        { "id": "view", "title": "View product", "icon": "arrow.up.right", "actions": [ { "type": "navigation", "nextScreen": "product", "params": { "product": "{{item}}" } } ] }
      ],
      "onPreviewTap": [ { "type": "navigation", "nextScreen": "product", "params": { "product": "{{item}}" } } ]
    }
  }
}
```

## ContextMenu

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `preview` | ContextMenuPreview | No | The content shown above the menu. Omit it to lift the component itself |
| `items` | ContextMenuItem[] | No | Menu actions, top to bottom. Empty or missing: preview only |
| `onPreviewTap` | Action[] | No | Runs when the preview is tapped (iOS commit). Usually a navigation to the full screen. Since 0.7.11 it runs as the preview starts to expand, and a navigation it starts skips its own transition: the expanding preview is the transition, and it dissolves straight into the new screen (as Mail and Photos open a previewed item). Before 0.7.11 the navigation ran after the expansion ended, with its own transition |
| `isEnabled` | [boolean](variables.md#boolean-coercion)/expression | No | Default `true`. `false` turns the long press off |

The menu replaces a `longPress` action on the same component. If both are set,
`contextMenu` wins and the engine logs `contextMenu.longPressIgnored`.

### ContextMenuPreview

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `component` | Component | Yes | Any component (inline or `templateId`). Laid out as its own root |
| `width` | number | No | Preview width. Default: screen width − 32 |
| `height` | number | No | Preview height. Default: the component's fitting height at `width` (its content's own height: no stretched gaps), at most 70% of the screen height |
| `cornerRadius` | number | No | Corner radius of the preview's platter. Default: the platform's (iOS about 13 pt). Set `0` for a square brand. Since 0.7.11; earlier engines draw the platform corners |

The preview is **not interactive**: it can show any content, but taps inside it
only run `onPreviewTap`. Put controls (add to bag, wishlist) in `items`.

### ContextMenuItem

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | Yes | Stable id |
| `title` | string/expression | Yes | Item title |
| `subtitle` | string/expression | No | Second line |
| `icon` | string/expression | No | SF Symbol name (Android: SF → Material table) |
| `destructive` | boolean | No | Red style |
| `isEnabled` | [boolean](variables.md#boolean-coercion)/expression | No | Default `true` |
| `hidden` | [boolean](variables.md#boolean-coercion)/expression | No | Default `false` |
| `actions` | Action[] | Yes | Run after the menu closes. A navigation here keeps its own transition (a zoom from the source element runs once the preview has shrunk back onto it), as the system "Open" item does |

### Scope

The preview, item titles and actions are evaluated in the scope of the component
that owns the menu. In a collection cell that includes `item` and `item.$index`.
Item titles are evaluated when the menu opens.

## Platform behavior

| Platform | Native |
|----------|--------|
| iOS | `UIContextMenuInteraction` on the component's view. `previewProvider` returns a view controller that renders `preview.component` with `preferredContentSize` = width × height. Items become `UIAction`s in one `UIMenu`. `willPerformPreviewActionForMenuWith` runs `onPreviewTap` in `animator.addAnimations` with `preferredCommitStyle = .pop`, its navigation without a transition of its own, so the expanding preview dissolves into the new screen (since 0.7.11; before, in `addCompletion`). `preview.cornerRadius` sets the `UIPreviewParameters.visiblePath` of the lift and dismissal and the platter's corners The lift, blur and haptic are the system ones |
| Android | Long press with `HapticFeedbackType.LongPress` opens a Material 3 `ModalBottomSheet`: the preview component on top (interactive taps run `onPreviewTap`), then each item as a list row (leading icon, title, optional subtitle). Choosing a row closes the sheet and runs its actions. Android has no peek-and-pop pattern; a quick-view sheet is the platform convention |
| Web | iOS: the screen blurs and dims, the preview scales in above a glass menu. Android: the bottom sheet |

## Accessibility

iOS adds the menu to the element's accessibility custom actions. Android adds
an `onLongClickLabel` ("Show actions") and exposes each item as a custom
accessibility action.
