# TabBarScreen

Tab-based navigation container.

## Content Properties

| Property | Type | Description |
|----------|------|-------------|
| `tabs` | Tab[] | Tab definitions |
| `initialTab` | string | Initial tab ID |
| `tintColor` | Color | Selected tab color |
| `unselectedColor` | Color | Unselected tab color |
| `badgeColor` | Color | Badge background (default system red) |
| `badgeTextColor` | Color | Badge text (default white) |
| `hidden` | boolean/expression | Hide component |

## Tab Structure

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique tab identifier |
| `label` | string | Tab label text |
| `icon` | string | SF Symbol name |
| `screen` | string | Screen ID to display |
| `badge` | string/expression | Badge value; empty or `0` hides it |
| `badgeColor` | Color | This tab's badge background |

## Example

<!-- @dsl-type: Component -->
```json
{
  "type": "tabBarScreen",
  "content": {
    "tabs": [
      { "id": "home", "label": "Home", "icon": "house.fill", "screen": "homeScreen" },
      { "id": "search", "label": "Search", "icon": "magnifyingglass", "screen": "searchScreen" },
      { "id": "favorites", "label": "Favorites", "icon": "heart.fill", "screen": "favoritesScreen" },
      { "id": "profile", "label": "Profile", "icon": "person.fill", "screen": "profileScreen" }
    ],
    "initialTab": "home",
    "tintColor": "#007AFF",
    "unselectedColor": "#8E8E93",
    "badgeColor": "#2D4D3A",
    "badgeTextColor": "#FFFFFF"
  }
}
```
