# Versioning

Two numbers, kept apart on purpose:

| Number | File | Example | Meaning |
|---|---|---|---|
| DSL version | `DSL_VERSION` | `1.1` | The language. Apps declare which DSL they need; SDKs declare the newest DSL they support (`maxSupportedDslVersion`). Minor bumps add backward-compatible features. |
| Release train | git tag of this repo | `0.4.0` | The SDK release. Every SDK ships with the same number on both platforms. |

## One release train

`app8-ios-sdk`, `app8-android-sdk`, `app8-ios-cloud-sdk` and
`app8-android-cloud-sdk` always release together under the same version as
this repo's tag. Android 0.4.0 renders exactly what iOS 0.4.0 renders.

Each SDK repo pins this repo in a `dsl.lock` file (one line: the tag). The
SDK's tests check out that tag and decode every JSON example in `docs/`.
SDKs do not include this repo as a git submodule: Swift Package Manager would
clone it for every app that installs the SDK.

## Shipping a DSL change

A DSL change is one change across the platforms:

1. Spec: edit `docs/`, add a row or update the row in `docs/platforms.md`.
2. iOS: implement in `app8-ios-sdk`.
3. Android: implement in `app8-android-sdk`.
4. Studio: implement in the web renderer (`shoppu-web/packages/app-dsl`).
5. Fixture: add a conformance fixture so the screenshot report covers it.
6. Release: tag this repo, bump `dsl.lock` and the version constant in both
   SDKs, tag both SDKs with the same version.

A feature row in `docs/platforms.md` may say `—` for a platform only when the
feature belongs to that platform's system chrome (for example predictive back
on Android).
