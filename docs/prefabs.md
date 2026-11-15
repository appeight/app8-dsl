# Prefabs

A **prefab** is a versioned feature package: screens, templates, styles and variables for one use case (onboarding, a loyalty card), written once and instantiated by any app with its own parameters (brand colours, fonts, copy, data sources, what happens on a key action).

[Templates](templates.md) reuse one component. Prefabs reuse a whole feature.

Prefabs exist only in the **source** of an app. The bundle builder expands every prefab instance into ordinary screens, templates and styles before the bundle is published. SDKs never see a prefab: a prefab needs no SDK support beyond the components its screens use (for example [`native`](components/native.md)), and a fix to a prefab reaches every app that uses it on that app's next bundle build.

> JSON on this page is prefab source. It contains `$param` nodes and `${…}` placeholders that only the bundle builder understands, so the SDK documentation tests skip it.

## Package layout

```
prefabs/loyalty-card/
  prefab.json            manifest (below)
  screens/home.json      one file per screen, named by the screen's local id
  screens/card.json
  screens/rewards.json
  screens/history.json
  components/RewardRow.json   app-level templates, named by template id
  components/StampSlot.json
  styles.json            optional: style entities owned by the prefab
```

## `prefab.json`

<!-- @dsl-skip: prefab source, expanded at bundle build -->
```json
{
  "id": "loyalty-card",
  "version": "1.0.0",
  "title": "Loyalty Card",
  "params": {
    "accentColor": { "type": "color", "default": "#2D4D3A", "description": "Buttons and highlights" },
    "headingFont": { "type": "string", "description": "PostScript name of the heading font" },
    "primaryButton": { "type": "style", "description": "Material style id of the app's primary button" },
    "rewards": { "type": "datasource", "default": "datasources/rewards" },
    "onRedeem": { "type": "actions", "default": [], "description": "Runs with the reward in scope as item" },
    "termsText": { "type": "string" },
    "exitScreen": { "type": "screen", "required": false }
  },
  "screens": ["home", "card", "rewards", "history"],
  "templates": ["RewardRow", "StampSlot"],
  "variables": {
    "${instance}_lastRewardId": { "type": "string", "initialValue": "", "persist": true }
  },
  "exports": {
    "entry": "home",
    "screens": ["home", "rewards"]
  },
  "requires": {
    "dsl": "0.6.0",
    "nativeModules": ["walletPass"],
    "datasources": ["datasources/loyaltyAccount"]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Package id, kebab-case. Apps refer to it as `<id>@<version>` |
| `version` | semver | Version of this package. A major bump means existing instances may need new params |
| `title` | string | Human name for tools |
| `params` | object | Parameter declarations, keyed by name; see [Params](#params) |
| `screens` | string[] | Local screen ids; each is read from `screens/<id>.json` |
| `templates` | string[] | Local template ids; each is read from `components/<id>.json` (a normal [template definition](templates.md)) |
| `styles` | string | Optional path of a style file (default `styles.json` when present): an array of style entities owned by the prefab |
| `variables` | object | App-level variables the prefab adds. Names must contain `${instance}` so two instances never share one |
| `exports` | object | `entry`: the screen the app opens the feature with. `screens`: local screen ids the app may navigate to. Other prefab screens are internal |
| `requires` | object | `dsl`: lowest DSL release the screens need. `nativeModules`: [`native`](components/native.md) modules the screens use. `datasources`: datasource ids the host must serve |

## Params

Each entry of `params`:

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | One of the types below. The builder checks the instance value against it |
| `default` | any | Value used when the instance does not set the param |
| `required` | boolean | Default: `true` when there is no `default`, else `false`. A missing required param fails the build |
| `description` | string | For tools and reviewers |

| Type | Value |
|------|-------|
| `string` | Any string; may contain runtime `{{…}}` expressions, which pass through |
| `number`, `boolean` | JSON number / boolean |
| `color` | Hex colour string (`#RRGGBB` or `#RRGGBBAA`) |
| `style` | Id of a style entity in the **app** (resolved by the app's style pointers, not namespaced) |
| `screen` | Id of a screen in the **app**, for navigating out of the feature |
| `datasource` | Datasource id the host serves, e.g. `"datasources/rewards"` |
| `actions` | One action or an array of actions |
| `object`, `array`, `any` | Any JSON of that shape |

An optional param that is not set and has no default resolves to `null`. In an object, a property whose whole value is such a param is removed.

## Instances in `app.json`

<!-- @dsl-skip: prefab source, expanded at bundle build -->
```json
{
  "app": { "id": "exampleStore", "title": "Example Store" },
  "prefabs": [
    {
      "id": "loyaltyCard",
      "prefab": "loyalty-card@1",
      "params": {
        "accentColor": "#2D4D3A",
        "headingFont": "Inter-Bold",
        "primaryButton": "primaryButtonMaterial",
        "rewards": "datasources/rewards",
        "onRedeem": [
          { "type": "emit", "name": "reward.redeemed", "payload": { "rewardId": "{{item.id}}" } }
        ],
        "termsText": "Points expire 12 months after they are earned."
      }
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| `id` | Instance id: letters and digits, starting with a letter (`^[A-Za-z][A-Za-z0-9]*$`), unique in the app. It namespaces everything the instance adds |
| `prefab` | `<package id>@<version>`. `@1` takes the newest `1.x.y`, `@1.2` the newest `1.2.y`, `@1.2.3` exactly that version |
| `params` | Values for the declared params. An undeclared name fails the build |

The app reaches the feature through its exports, namespaced: `{ "type": "navigation", "nextScreen": "loyaltyCard_home" }`.

## Substitution

Param values are inserted with forms that cannot be mistaken for runtime expressions (`{{…}}`), which the builder never touches.

| Form | Where | Result |
|------|-------|--------|
| `{ "$param": "name" }` | Any JSON value position; the object must have no other keys | Replaced by the param's value with its JSON type (string, number, object, action list, …) |
| `{ "$spread": "name" }` | An array element; the param must hold an array (`actions` params are arrays) | The param's elements are inserted in place |
| `"${param.name}"` | Inside any string | The param's value as text. Only `string`, `color`, `style`, `screen`, `datasource`, `number` and `boolean` params may be used this way |
| `"${instance}"` | Inside any string | The instance id (`loyaltyCard`) |
| `"${id.name}"` | Inside any string | The namespaced id of a prefab screen, template or style: `${id.rewards}` → `loyaltyCard_rewards`. Use it where an id sits inside an expression, which the builder does not rewrite |
| `"$${"` | Inside any string | A literal `${` |

Object keys are never substituted, except `${instance}` in the names of `variables`.

A screen using each form:

<!-- @dsl-skip: prefab source, expanded at bundle build -->
```json
{
  "id": "rewards",
  "type": "screen",
  "content": {
    "variables": {
      "rewards": { "type": "array", "source": "${param.rewards}" }
    },
    "children": [
      {
        "id": "rewardList",
        "type": "collection",
        "content": {
          "properties": { "data": "{{rewards}}", "templateName": "RewardRow" },
          "actions": {
            "onItemTap": [
              { "$spread": "onRedeem" },
              { "type": "haptic", "hapticStyle": "light" }
            ]
          }
        }
      },
      {
        "id": "showCard",
        "type": "button",
        "content": {
          "properties": { "text": "Show card" },
          "style": { "material": { "id": "${param.primaryButton}" } },
          "actions": {
            "tap": [
              { "type": "updateVariable", "variableName": "${instance}_lastRewardId", "value": "" },
              { "type": "navigation", "nextScreen": "card" }
            ]
          }
        }
      },
      {
        "id": "terms",
        "type": "label",
        "content": {
          "properties": { "text": { "$param": "termsText" } }
        }
      },
      {
        "id": "historyButton",
        "type": "button",
        "content": {
          "properties": { "text": "History" },
          "actions": {
            "tap": { "type": "navigation", "nextScreen": "{{hasVisits ? '${id.history}' : '${id.card}'}}" }
          }
        }
      }
    ]
  }
}
```

## Namespacing

Everything the prefab adds to the app gets the prefix `<instanceId>_`, so two instances (or an instance and the app's own screens) never collide:

| Defined by the prefab | Local id | In the bundle |
|-----------------------|----------|---------------|
| Screen | `rewards` | `loyaltyCard_rewards` |
| Template (`components/`) | `RewardRow` | `loyaltyCard_RewardRow` |
| Style entity (`styles.json`) | `stampChip` | `loyaltyCard_stampChip` |
| App variable | `${instance}_lastRewardId` | `loyaltyCard_lastRewardId` |

The separator is `_`, not `.`: SDKs build component paths by joining ids with `.` (`screen.parent.child`) and read the screen id as the first segment, so a dotted screen or component id would break event screen ids, sibling constraints and shared-element transitions.

The builder rewrites references to prefab-owned ids. A reference is rewritten only when it is a literal string (not a `{{…}}` expression) equal to a local id the prefab defines; anything else is left alone, so references to the app's own screens, templates and styles keep working.

| Reference | Rewritten when it names a prefab… |
|-----------|-----------------------------------|
| `nextScreen` (navigation action) | screen |
| `exports.entry`, `exports.screens` | screen |
| `templateId` (component), `properties.templateName` and section `templateName` (collection), `template` when it is a string | template |
| Style pointer (a style entity with `id` and no `content`) anywhere under `style` or `states.*.style` | style entity |
| `id` of a screen, template or style entity defined by the prefab | (renamed itself) |

Component ids **inside** a screen (`"id": "rewardList"`) are not prefixed: they are scoped to their screen's component path already, and leaving them alone keeps layout `target`s, `childStates`, `focus` targets and transition keys valid without rewriting.

Ids inside expressions are not rewritten; write them with `${id.name}`. Variable names are not rewritten; spell app variables with `${instance}` everywhere they appear (`"{{${instance}_lastRewardId}}"`).

## Expansion

The bundle builder expands every entry of `prefabs` in this order, and fails the build on the first error:

1. **Resolve** `prefab` to one package version.
2. **Check params**: no undeclared names, every required param set, every value matches its type. Apply defaults.
3. **Substitute** in every screen, template, style and variable of the package: `$param` and `$spread` nodes first, then `${param.…}`, `${instance}`, `${id.…}` and `$${` in strings.
4. **Namespace**: rename prefab-owned screens, templates, style entities with `<instanceId>_` and rewrite the references listed above.
5. **Verify**: no `$param` / `$spread` node or `${param.` / `${id.` / `${instance}` text is left; no namespaced id collides with an id the app or another instance already defines; every `${id.name}` named a prefab-owned id; each `native` component whose module is in `requires.nativeModules` has a `fallback` (warning when it does not). A reference from the app to a prefab screen that is not exported is a warning.
6. **Merge** the screens into `screens`, templates into `templates`, style entities into the styles, variables into `app.variables`, and drop `prefabs` from the built `app.json`.

The result is an ordinary bundle. Studio previews run the same expansion, so what an author sees is what ships.

`requires.nativeModules` and `requires.datasources` are a contract with the host app, which the builder cannot check: the host registers each module (see [native component host registration](components/native.md#host-registration)) and serves each datasource (see [host integration](host-integration.md#datasources)). A module the host has not registered shows its `fallback`.

## Not supported (yet)

- Prefabs inside prefabs.
- Overriding a single screen of an instance: change params, or fork the package.
- Translations owned by the prefab: pass copy as params, or put `$i18n` keys the app's translation bundle defines into string params.
