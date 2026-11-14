# Picker

A single-choice selector. Renders as a tap-to-open menu (`UIMenu`) or an inline segmented control (`UISegmentedControl`). Two-way bound to a string variable.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.options` | Option[] | | Selectable choices |
| `properties.selectedValue` | string/expression | | Current selection. Accepts an expression, e.g. `"{{selectedColor}}"` |
| `properties.bindVariable` | string | | Variable name for two-way binding (no `{{}}`) |
| `properties.bindKey` | string/expression | | With an `object` variable in `bindVariable`: the key the selection is written under, e.g. `"{{item.handle}}"`. One map holds a choice per item |
| `properties.displayMode` | DisplayMode | `menu` | `menu` or `segmented` |
| `properties.placeholder` | string | | Text shown in `menu` mode when nothing is selected |
| `properties.isEnabled` | boolean/expression | `true` | Whether the picker accepts input |
| `hidden` | boolean/expression | | Hide component |

> **Binding vs. value**: set `bindVariable` to the bare variable **name**; set `selectedValue` to an **expression**. The picker writes the selected option's `value` (not its `label`) back to the variable. See [variables.md → Variable Binding](../variables.md#variable-binding).

### Option

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `value` | string | Yes | Stored value written to the bound variable |
| `label` | string | Yes | Text shown to the user |
| `icon` | string | No | SF Symbol name shown beside the label |

## DisplayMode Values

| Value | Renders as | Best for |
|-------|------------|----------|
| `menu` | Tap-to-open dropdown menu | Many options, compact footprint |
| `segmented` | Inline segmented control | 2–4 options, all visible at once |

## Menu mode look

In `menu` mode the picker is a plain pull-down button: the selected label, then
an indicator symbol. Tap opens the platform menu with a checkmark on the
selected option. The choice is written back on selection.

| Platform | Native control |
|----------|----------------|
| iOS | `UIButton` (plain configuration, no background) with `menu`, `showsMenuAsPrimaryAction = true`, `changesSelectionAsPrimaryAction = true`. Options are `UIAction`s with `state = .on` for the selected one |
| Android | A text row with a trailing Material icon, anchoring a Material 3 `DropdownMenu`. The selected item has a leading check. Without `style.label` / `style.indicator` the Material 3 exposed dropdown field is used |

The button hugs its content: label width plus `indicatorSpacing` plus the
symbol. Leading-aligned in its frame.

## Style: PickerStyle

| Property | Type | Description |
|----------|------|-------------|
| `text` | TextModel | Label text style (menu mode button) |
| `label` | TextModel | Menu mode: the pull-down button's title style (font, size, color). Opts into the plain pull-down look |
| `indicator` | string | Menu mode: SF Symbol after the title. Default `chevron.up.chevron.down`. `""` hides it. Android maps it through the SF → Material table |
| `indicatorColor` | Color | Indicator tint. Default: `label` color |
| `indicatorSize` | number | Indicator point size. Default: 0.8 × `label` font size |
| `indicatorSpacing` | number | Gap between title and indicator. Default `6` |
| `selectedSegmentTintColor` | Color | Selected segment color (segmented mode) |
| `material` | Material | Background |
| `alpha` | number | Opacity (0.0–1.0) |
| `contentMode` | ContentMode | Content alignment |

## Examples

**Segmented control:**

```json
{
  "type": "picker",
  "id": "sortPicker",
  "content": {
    "properties": {
      "displayMode": "segmented",
      "options": [
        { "value": "new", "label": "Newest" },
        { "value": "top", "label": "Top" },
        { "value": "hot", "label": "Trending" }
      ],
      "selectedValue": "{{sortOrder}}",
      "bindVariable": "sortOrder"
    },
    "layout": { "leading": 20, "trailing": 20, "top": 16 }
  }
}
```

**Menu with icons and a placeholder:**

```json
{
  "type": "picker",
  "content": {
    "properties": {
      "displayMode": "menu",
      "placeholder": "Choose a color",
      "options": [
        { "value": "red", "label": "Red", "icon": "circle.fill" },
        { "value": "blue", "label": "Blue", "icon": "circle.fill" }
      ],
      "bindVariable": "selectedColor"
    }
  }
}
```

**Pull-down variant chooser per product card** (a choice per item, kept in an object map):

```json
{
  "type": "picker",
  "id": "variantMenu",
  "content": {
    "properties": {
      "displayMode": "menu",
      "options": "{{item.variants}}",
      "selectedValue": "{{selectedVariants[item.handle] != null ? selectedVariants[item.handle] : item.variant}}",
      "bindVariable": "selectedVariants",
      "bindKey": "{{item.handle}}"
    },
    "style": {
      "label": { "fontSize": 13, "color": "#8A8A8A" },
      "indicator": "chevron.up.chevron.down"
    },
    "layout": { "leading": 0, "top": 4 }
  }
}
```

`options` can be an expression that gives an array of `{value, label}` objects.

## See Also

- [Forms & Inputs](../forms.md)
- [DatePicker](date-picker.md) — for dates and times
- [variables.md](../variables.md) — binding and expressions
