# Design best practices for store apps

Rules for generating brand store apps (catalogue, product, cart) that look native and on-brand. They come from design reviews of the demo apps (Facetheory, Slick Gorilla, smol, Valentte, Gloveglu, Rollr). Follow them unless the brand's own site clearly does otherwise.

> Related: [collections-best-practices.md](collections-best-practices.md) for list and grid mechanics, [layout.md](layout.md) for constraints.

## Scrolling and the top bar

- **A screen scrolls as one piece.** A title, intro text or filters above a list must scroll with the list. Never pin a header above a scrolling grid (Apple's Human Interface Guidelines: content scrolls under bars, not under other content).
- **Pattern for a title + intro + grid:** a `scrollView` pinned to all four `superview` edges (`contentInsetAdjustment: "automatic"`), holding a vertical `stackView` with the header views and a `collection` whose `layout.scrollEnabled` is `false`, so the grid sizes to its content.

```json
{ "type": "scrollView", "id": "page",
  "content": {
    "properties": { "direction": "vertical", "showsIndicator": false, "contentInsetAdjustment": "automatic" },
    "layout": { "constraints": [
      { "type": "top", "target": "superview" }, { "type": "leading", "target": "superview" },
      { "type": "trailing", "target": "superview" }, { "type": "bottom", "target": "superview" } ] },
    "children": [ { "type": "stackView", "id": "pageStack",
      "content": {
        "properties": { "axis": "vertical", "alignment": "fill" },
        "layout": { "constraints": [
          { "type": "top", "target": "superview" }, { "type": "leading", "target": "superview" },
          { "type": "trailing", "target": "superview" }, { "type": "bottom", "target": "superview" } ] },
        "children": [
          { "type": "view", "id": "header", "content": { "children": [ "…title and intro labels…" ] } },
          { "type": "collection", "id": "grid", "content": { "properties": {
            "data": "{{list.products}}", "templateName": "ProductCard",
            "layout": { "type": "grid", "columns": 2, "itemHeight": 372, "scrollEnabled": false,
                        "contentInsets": { "left": 10, "right": 10, "bottom": 40 } } } } }
        ] } } ] } }
```

- **Let content run under the bar.** Pin the scroll view to `superview` top (not `safeArea`) with automatic inset adjustment. iOS 26 then draws its progressive blur (scroll-edge effect) under the navigation bar by itself. Leave `navigationBar.topEdgeEffect` at `automatic` unless the design asks otherwise.
- Today the iOS engine has two collection limits: `sectionDefinitions` can hang, and grid layouts don't show section headers. Use the pattern above instead of a section header.

## Content

- **No item counts.** Don't show "19 products", "31 PRODUCTS" or similar on collection or category screens. A shopper doesn't care; it reads like a back office.
- **Brand copy verbatim.** Use the brand's own words from its site; otherwise plain UI words. Don't invent taglines or eyebrows.
- **Truncated teasers, full text on tap.** Tiles may truncate a description to 3 lines only when the tap opens a screen that shows the full text.

## Typography

- **Tight leading for multi-line text.** Body and subheadline paragraphs: line height multiplier ≈ 1.15–1.2. Large headlines ≈ 1.05–1.1. Default 1.35+ looks loose on mobile.
- **No orphans.** Labels avoid a lone last word (iOS `.pushOut`, Android `LineBreak.Paragraph`, web `text-wrap: pretty`; the engines apply it). Don't hand-insert line breaks to fix wrapping.
- **Statement blocks:** eyebrow (small caps or mono, as the site), then the whole statement as one large multi-line headline, then a button. Don't split it into a small title plus a body paragraph when the site shows one headline.

## Brand fidelity

- **Take colours, fonts and button styles from the site's CSS, not from screenshots.** Screenshots shift colour. Read the CSS variables and `.btn` rules for the exact hex values, borders and text transform.
- **Buttons:** primary = solid brand colour with the site's button font and case. Secondary = outline (1px brand colour, transparent or white fill). Buttons on photos = the site's light button (usually white with dark text).
- **Use the brand's palette only.** Don't introduce dark blocks (near-black buttons, steppers, chips) that the brand never uses. On light, airy brands, quantity steppers use the secondary outline style.

## Commerce patterns

- **Added state:** once an item is in the bag, the Add button becomes one row: `[N Added ✓] [−] [+]`. The Added part is calm (a light brand tint, or grey on dark brands); minus and plus match the cart's steppers. Minus at 1 removes the item and brings Add back. Match items by a key that includes the variant.
- **Cart steppers** use the same style as the Added-row steppers.

## Images and banners

- **Banners and hero covers run edge to edge** (no side inset) and keep the image's aspect ratio vertically.
- **A promo strip sits directly on the cover below it.** No gap between a thin strip and a full-bleed hero.
- **Text over photos gets a gentle bottom gradient:** black when the text is white, white when the text is dark. Never a brand-coloured tint.
- **Category and concern tiles:** the photo stays clean (nothing laid over it) and is the centre of attention; the title and text go below the photo.

## Native details

- **Symbols inline with text** (checkmarks in "Added ✓") should be SF Symbols on iOS, not Unicode glyphs. *[Planned: label support for inline symbols.]*
- **Declare a `type` for every variable**, including computed component variables. The native engines require it; a missing type silently breaks the component on iOS.
- **Keep spacing on a rhythm.** Pick a small set of values per screen (e.g. 10/16/20 margins, 12/24/28/32 vertical gaps) and use them consistently, rather than one-off numbers.
