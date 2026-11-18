# Toggle

A native on/off switch (`UISwitch`). Two-way bound to a boolean variable.

## Content Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `properties.isOn` | [boolean](../variables.md#boolean-coercion)/expression | `false` | Current on/off state. Accepts an expression, e.g. `"{{darkMode}}"` |
| `properties.bindVariable` | string | | Variable name for two-way binding (no `{{}}`) |
| `properties.isEnabled` | [boolean](../variables.md#boolean-coercion)/expression | `true` | Whether the toggle accepts input. Accepts an expression |
| `properties.isHidden` | [boolean](../variables.md#boolean-coercion)/expression | | Hide component; see [Visibility](../components.md#visibility) |

> **Binding vs. value**: set `bindVariable` to the bare variable **name** (`"darkMode"`); set `isOn` to an **expression** (`"{{darkMode}}"`). Most toggles only need `bindVariable` — the engine reads the current value and writes user changes back automatically. See [variables.md → Variable Binding](../variables.md#variable-binding).

## Boolean Coercion

`isOn` and the bound variable follow the DSL's [boolean coercion](../variables.md#boolean-coercion):
`true`, non-zero numbers, `"true"` and `"1"` are on; any other string and `0` are off.

## Style: ToggleStyle

| Property | Type | Description |
|----------|------|-------------|
| `onTintColor` | Color | Track color when on |
| `thumbTintColor` | Color | Thumb (knob) color |
| `material` | Material | Background |
| `alpha` | number | Opacity (0.0–1.0) |
| `contentMode` | ContentMode | Content alignment |

## Example

```json
{
  "type": "toggle",
  "id": "darkModeToggle",
  "content": {
    "properties": {
      "isOn": "{{darkMode}}",
      "bindVariable": "darkMode"
    },
    "style": {
      "onTintColor": "#34C759"
    },
    "layout": { "trailing": 20, "centerY": 0 }
  }
}
```

A toggle that disables itself until a prerequisite is met:

```json
{
  "type": "toggle",
  "content": {
    "properties": {
      "bindVariable": "notificationsEnabled",
      "isEnabled": "{{hasGrantedPermission}}"
    }
  }
}
```

## See Also

- [Forms & Inputs](../forms.md) — combining inputs, binding, and validation
- [Slider](slider.md), [Picker](picker.md) — other bound inputs
- [variables.md](../variables.md) — binding and expressions
