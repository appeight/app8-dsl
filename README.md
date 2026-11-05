# App8 DSL

The App8 DSL is a JSON language for native mobile UI. One app definition
renders natively on iOS (UIKit) and Android (Jetpack Compose), with reactive
variables, expressions, component states and flow-based navigation.

This repo is the single source of truth for the language, shared by:

- [`app8-ios-sdk`](https://github.com/appeight/app8-ios-sdk): iOS renderer.
- [`app8-android-sdk`](https://github.com/appeight/app8-android-sdk): Android renderer.

## Contents

- [`docs/index.md`](docs/index.md): the reference, starting point.
- [`docs/platforms.md`](docs/platforms.md): what differs between iOS and
  Android, platform floors, per-platform overrides, the feature matrix.
- [`VERSIONING.md`](VERSIONING.md): the DSL version, the shared release
  train, and how a DSL change ships on both platforms.
- `DSL_VERSION`: the current language version.

## License

Apache 2.0. See [LICENSE](LICENSE).
