# Animations

The `animation` primitive describes how a property change should transition over time. It drives:

- **State transitions** — every `state.animation` field on a `StatefulContent` view (button, view, etc.). When the component moves between states (touchDown → "pressed", focus, hover, …), the runner uses this descriptor to animate **alpha, transform, and material layers** (gradient fill, shadow, outline, cornerRadius) under one synchronized transition.
- **Per-property variable changes** *(parsing only — runtime hookup pending)* — properties driven by `{{expression}}` values can declare an `animation` next to the `value` so future variable mutations animate.
- **Default press feedback** — buttons without explicit `states` use a built-in animation as touch-down/up feedback.
- **Screen transitions** — the [transition](transitions.md) system reuses this primitive for the timing of screen-to-screen animations.

The same primitive shows up everywhere — one schema, one runner, one mental model.

## Anatomy

```jsonc
{
  "duration": 0.15,                 // seconds, required
  "delay": 0,                       // seconds, optional, default 0
  "options": ["beginFromCurrent"],  // optional, see Options

  // Timing — supply at most one of `curve`, `cubicBezier`, or `spring`.
  // If you pass several, precedence is: spring > cubicBezier > curve.
  "curve": "easeOut",               // linear | easeIn | easeOut | easeInOut
  "cubicBezier": [0.25, 0.1, 0.25, 1.0],
  "spring": { "damping": 0.8, "velocity": 0.9, "mass": 1.0, "stiffness": 100 }
}
```

| Field | Type | Notes |
|-------|------|-------|
| `duration` | `Number` | Seconds. Required. UIView's spring API requires a duration even though a true spring runs until rest. |
| `delay` | `Number` | Seconds. Default `0`. |
| `options` | `[String]` | See [Options](#options). |
| `curve` | `"linear" \| "easeIn" \| "easeOut" \| "easeInOut"` | Named easing. |
| `cubicBezier` | `[x1, y1, x2, y2]` | Custom cubic-bezier control points. |
| `spring` | `{ damping, velocity, mass?, stiffness? }` | See [Spring](#spring). |

### Options

| Value | Effect |
|-------|--------|
| `beginFromCurrent` | Maps to `UIView.AnimationOptions.beginFromCurrentState` so a re-press during a release picks up the in-flight presentation values. |
| `allowUserInteraction` | Permits touch input during the animation. |
| `repeat` | Loops the animation forever. See [Repeating animations](#repeating-animations). |
| `autoreverse` | Plays back in reverse after each forward pass. |

State-driven animations always run with `beginFromCurrentState` and `allowUserInteraction` added on top of whatever you specify in `options` — re-pressing during settle should always feel right. You don't need to pass them.

### Spring

| Field | Default | Notes |
|-------|---------|-------|
| `damping` | `0.85` | Damping fraction in `[0, 1]`. Lower = bouncier. Maps to `usingSpringWithDamping:` for view animations. |
| `velocity` | `0` | Initial velocity. Positive values continue the gesture's direction. |
| `mass` | *unset* | Optional. When provided, the runner uses `UIViewPropertyAnimator` with `UISpringTimingParameters(mass:stiffness:damping:initialVelocity:)`. |
| `stiffness` | *unset* | Optional. Required alongside `mass`. |

Most authors only need `damping` and `velocity`. The standard recipe for a settle is `{ damping: 0.8, velocity: 0.9 }`.

## State Transitions

Each `state.animation` describes how the component animates **into** that state. Pair `pressed` with a snappy ease-out and `normal` with a longer settle so the press feels reactive but the release feels smooth:

```json
{
  "type": "view",
  "content": {
    "triggers": { "touchDown": "pressed", "touchUp": "normal" },
    "defaultStateName": "normal",
    "states": {
      "normal": {
        "style": { "alpha": 1.0, "material": [...] },
        "animation": {
          "duration": 0.4,
          "spring": { "damping": 0.8, "velocity": 0.9 }
        }
      },
      "pressed": {
        "style": { "alpha": 0.85, "material": [...] },
        "animation": {
          "duration": 0.15,
          "curve": "easeOut"
        }
      }
    }
  }
}
```

What animates during a state transition:

- `alpha`, `transform` (UIView)
- Gradient fill colors and locations (CAGradientLayer)
- `shadowColor`, `shadowRadius`, `shadowOffset`, `shadowOpacity`
- Outline `strokeColor` (when only the color changes — `lineWidth` / `position` changes still recreate the layer)
- `cornerRadius`

All run under one duration so the visual change reads as a single coordinated event. See [states.md](states.md) for the trigger / child-state model.

## Reusable Registry

Define named animations once at the app level and reference them from anywhere:

```jsonc
// app.json
{
  "title": "MyApp",
  "navigation": { /* … */ },
  "animations": [
    {
      "id": "fastPress",
      "type": "animation",
      "content": { "duration": 0.15, "curve": "easeOut" }
    },
    {
      "id": "settle",
      "type": "animation",
      "content": {
        "duration": 0.4,
        "spring": { "damping": 0.8, "velocity": 0.9 }
      }
    }
  ]
}
```

Reference by id — same `Pointer` form as [styles](styles.md):

```json
{
  "states": {
    "pressed": { "animation": { "id": "fastPress" } },
    "normal":  { "animation": { "id": "settle"    } }
  }
}
```

The engine resolves pointers at decode time using the registry from `app.json`. A pointer that doesn't exist in the registry is preserved as-is and falls back to instantaneous at runtime.

## Per-Property Animations

Property values that drive animatable view properties accept an optional `animation` describing how variable changes should transition. Both shapes parse — wrap when you want the change to animate, leave it bare otherwise:

```json
{
  "properties": {
    "transformTranslateX": {
      "value": "{{ x }}",
      "animation": { "duration": 0.2, "curve": "easeOut" }
    },
    "alpha": {
      "value": "{{ visible ? 1 : 0 }}",
      "animation": { "id": "settle" }
    }
  }
}
```

```json
{
  "properties": {
    "transformTranslateX": "{{ x }}"
  }
}
```

### Where it works today

| Component | Animatable expression-driven properties |
|---|---|
| `view` | `transformScale`, `transformTranslateX`, `transformTranslateY`, `transformRotation`, `alpha`, `backgroundColor` |
| every component | `isHidden` (see [Animated visibility](#animated-visibility)) |
| `label` | `backgroundColor` |
| `icon` | `tintColor`, `backgroundColor` |
| `shape` | `progress` |

### Precedence

When a variable change fires and the property is animatable, the runtime picks an `Animation.Inline` to drive `AnimationRunner.run` in this order:

1. **Per-property `animation`** wrapped on the property value — wins when present. Pointer references resolve at decode time against the app-level `animations` registry.
2. **Legacy fallback** — preserves bit-for-bit historic behavior so existing screens animate exactly as before:
   - `transformScale` / `transformTranslateX` / `transformTranslateY`: `0.3s spring (damping 0.75, velocity 0.3)`
   - `transformRotation` and `isHidden`: instantaneous
   - `alpha`: `0.25s easeOut`
   - `shape.progress`: derived from the legacy `animationDuration` + `animationCurve` siblings on the same Properties object
   - All other color/visual properties: instantaneous (matches what they did before)

Per-property animation also takes precedence over the active state animation. Rationale: an author who attached a descriptor to *this property* expects it to win over a generic state transition.

### First apply

The first time a property gets a value (component initialization, or first time a `dynamicBackgroundView` is added) is always **instantaneous** regardless of the descriptor — there's no meaningful "from" value to animate from. Subsequent variable-driven changes use the descriptor. The exception is a `repeat` animation, which starts its loop on the first apply (see [Repeating animations](#repeating-animations)).

### Notes

- A bare `isHidden` (no `animation`) still applies at once.
- Layout-driving expressions (`width` / `height`) are not animatable through this path — they need a separate layout-transition API.

### transformRotation

`view.properties.transformRotation`: degrees, clockwise, about the view's centre. A number or an expression, bare or wrapped with an `animation`. It composes with the other transform properties and with `style.transform` as translate, then rotate, then scale (iOS `CGAffineTransform(translationX:y:).rotated(by:).scaledBy(x:y:)`, Android `graphicsLayer { translationX; translationY; rotationZ; scaleX; scaleY }`, web `translate() rotate() scale()`). An animated change takes the shortest path only when the author writes it: the value interpolates numerically, so `0 → 180` turns clockwise and `180 → 0` turns back. A full turn turns too: `0 → 360` spins once (since 0.7.9 on iOS, which stood still before because the start and end transforms are equal).

A disclosure chevron that turns as its row opens:

```json
{
  "id": "chevronTurn",
  "type": "view",
  "content": {
    "properties": {
      "transformRotation": {
        "value": "{{ includes(openRows, 'shipping') ? 180 : 0 }}",
        "animation": { "duration": 0.3, "cubicBezier": [0.33, 1, 0.68, 1] }
      }
    },
    "children": [
      { "id": "chevron", "type": "icon", "content": { "properties": { "type": "symbol", "name": "chevron.down" } } }
    ]
  }
}
```

### Repeating animations

> Since 0.7.9 on iOS, Android and the web renderer. Engines up to 0.7.8 play
> a `repeat` once on the web, and an iOS rotation by a full turn does not move.

A per-property `animation` with `"options": ["repeat"]` loops from the
property's start value to its value, then starts over, for as long as the
property keeps that value. With `autoreverse` it goes back and forth instead.

- **Start value.** On a change, the previous value. On the first apply, and
  whenever the view is set up again (a reused collection cell, a screen built
  again), the property's rest value: `0` for `transformRotation`,
  `transformTranslateX` and `transformTranslateY`, `1` for `transformScale` and
  `alpha`. So a value that is already set when the view appears still loops: a
  sticker with `"transformRotation": { "value": -360, "animation": { "duration": 10, "curve": "linear", "options": ["repeat"] } }`
  spins from the start, and an expression such as `{{spin ? -360 : 0}}` spins
  once `spin` turns true.
- **Rotation is an angle.** A rotation interpolates the angle in degrees, not the
  transform, so a full turn (`0 → -360`, `0 → 720`) spins instead of standing still
  (the start and end transforms are the same).
- **Always running while visible.** The loop runs whenever the view is on screen:
  after a cell is reused or scrolled away and back, after a tab switch, under and
  after a sheet, and after the app returns from the background. A loop that was
  stopped by the platform restarts from its start value. Loops on views off
  screen may be paused to save power.
- **Stopping.** A change to a value without `repeat` (or to a bare value) stops
  the loop and animates (or jumps) to the new value. A rest-value loop (`0 → 0`)
  does nothing.
- Repeat applies to the per-property `animation` of `transformRotation`,
  `transformTranslateX`, `transformTranslateY`, `transformScale` and `alpha`.
  State transitions ignore `repeat`.

A ticker that scrolls a 1200 pt strip forever (for text, `scrollView.autoScroll`
is usually simpler):

```json
{
  "transformTranslateX": {
    "value": -1200,
    "animation": { "duration": 30, "curve": "linear", "options": ["repeat"] }
  }
}
```

### Animated visibility

`properties.isHidden` on any component accepts the wrapped form. When its value changes after the first apply, the change animates with the descriptor; the bare form keeps applying at once.

```json
{
  "id": "shippingBody",
  "type": "view",
  "content": {
    "properties": {
      "isHidden": {
        "value": "{{ !includes(openRows, 'shipping') }}",
        "animation": { "duration": 0.3, "cubicBezier": [0.33, 1, 0.68, 1] }
      }
    },
    "children": [ … ]
  }
}
```

**In a `stackView`** (an arranged subview, the disclosure / accordion case) the change is one animated layout pass, as UIKit does with `UIView.animate { view.isHidden = …; view.alpha = …; root.layoutIfNeeded() }`:

- The component's size along the stack axis grows from 0 to its laid-out size when it appears, and shrinks to 0 when it disappears; the stack's spacing around it grows or shrinks with it.
- Every frame that changes as a consequence moves and resizes on the same curve and duration: the siblings after it, the stack, its ancestors, the content size of an enclosing scroll view, and views constrained to any of them. Nothing jumps to its final place first.
- The component's content is laid out at its final size from the first frame and clipped to the component's animating bounds, so it is revealed (or covered) by the moving edge rather than squeezed; there is no overlap with the views after it.
- Alpha fades on the same timing: 0 → 1 while appearing, 1 → 0 while disappearing. At the end of a disappearance the component is hidden (not drawn, no touches, no space), exactly as with the bare form.
- A new change while one is running starts from the current, in-flight state (`beginFromCurrent`), so tapping a row twice quickly reverses smoothly.

**Elsewhere** (not an arranged subview) it keeps its frame either way, as a hidden view does: the change is an alpha cross-fade (1 → 0 then hidden, or shown at 0 → 1).

Shared by all renderers:

- The first apply (the screen appearing, a cell being bound or reused for another item) is instantaneous: a section that starts open is open, without an animation.
- Reduce Motion: the change applies at once.
- The component's own `alpha` (style or property) is the value it fades to; an animated `alpha` property on the same view keeps its own timing.
- Touches go to the component from the moment it starts appearing and stop the moment it starts disappearing.
- Scroll position: the content above the component does not move; a scroll view that would be scrolled past its new end (the last section closing at the bottom) animates its offset back inside on the same curve, without a bounce.

For a disclosure row, give the body, the chevron and anything else that follows the same state one shared descriptor, usually a cubic ease-out of about 0.3 s (`"cubicBezier": [0.33, 1, 0.68, 1]`): the content below, the body's fade and the chevron's turn then move as one.

## Defaults

| Situation | Behavior |
|-----------|----------|
| No `animation` on a state | Instantaneous transition. |
| No `states` on a button | Built-in press-feedback animation (~150ms ease-out). |
| `curve: "spring"` (legacy, no parameters) | Spring with `damping: 0.85`, `velocity: 0`. |
| Reduce Motion enabled (system setting) | All animations collapse to instantaneous. |
| Animation pointer fails to resolve | Instantaneous + warning. |

## Quick Reference

```json
// Snappy press feedback
{ "duration": 0.15, "curve": "easeOut" }

// Bouncy settle on release
{ "duration": 0.4, "spring": { "damping": 0.8, "velocity": 0.9 } }

// Custom timing curve
{ "duration": 0.3, "cubicBezier": [0.25, 0.1, 0.25, 1.0] }

// Critically damped layout settle
{ "duration": 0.5, "spring": { "damping": 1.0, "velocity": 0 } }

// Linear, kept simple
{ "duration": 0.2, "curve": "linear" }
```
