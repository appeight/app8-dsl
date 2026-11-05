#!/usr/bin/env bash
# Cuts one release of the shared App8 train: tags app8-dsl, both engines and
# both cloud SDKs with the same version, in dependency order, and creates the
# GitHub releases. Run from anywhere; repos are siblings of this one.
#
#   bash app8-dsl/scripts/release-train.sh 0.4.0
#
# Release notes come from releases/<version>.md on app8-dsl origin/main.
#
# Tags each repo's origin/main (local checkouts may have unrelated work in
# progress; they are not touched). Checks that EngineVersion, SDKVersion and
# dsl.lock on origin/main already say <version>.
set -euo pipefail

V=${1:?usage: release-train.sh <version>}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
ORG=appeight

say() { printf '\n== %s\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

check_main() { # repo
  local d=$ROOT/$1
  git -C "$d" fetch -q origin --tags
  git -C "$d" rev-parse -q --verify "refs/tags/$V" >/dev/null && die "$1: tag $V already exists"
  return 0
}
show() { git -C "$ROOT/$1" show "origin/main:$2"; } # repo path

tag_and_release() { # repo title notes
  local d=$ROOT/$1
  git -C "$d" tag -a "$V" origin/main -m "$2 $V

$3"
  git -C "$d" push -q origin "$V"
  gh release create "$V" -R "$ORG/$1" --title "$2 $V" --notes "$3" >/dev/null
  echo "released $ORG/$1 $V"
}

NOTES=$(git -C "$ROOT/app8-dsl" show "origin/main:releases/$V.md" 2>/dev/null) || die "missing releases/$V.md on app8-dsl origin/main"

say "Preflight"
for r in app8-dsl app8-android-sdk app8-ios-sdk app8-android-cloud-sdk; do check_main "$r"; done
show app8-android-sdk engine-core/src/main/kotlin/dev/app8/engine/core/EngineVersion.kt | grep -q "CURRENT: String = \"$V\"" || die "Android EngineVersion != $V"
show app8-ios-sdk Sources/App8Engine/Core/EngineVersion.swift | grep -q "current = \"$V\"" || die "iOS EngineVersion != $V"
[[ "$(show app8-android-sdk dsl.lock)" == "$V" && "$(show app8-ios-sdk dsl.lock)" == "$V" ]] || die "dsl.lock != $V"
echo ok

say "1/5 app8-dsl"
tag_and_release app8-dsl "App8 DSL" "$NOTES"

say "2/5 app8-android-sdk (release workflow publishes dev.app8:engine to GitHub Packages)"
tag_and_release app8-android-sdk "App8 Android SDK" "$NOTES"

say "3/5 app8-ios-sdk"
tag_and_release app8-ios-sdk "App8Engine (iOS)" "$NOTES"

say "4/5 app8-ios-cloud-sdk (merge the $V bump PR, then tag)"
pr=$(gh pr list -R "$ORG/app8-ios-cloud-sdk" --head "release/$V" --json number -q '.[0].number')
[[ -n "$pr" ]] && gh pr merge "$pr" -R "$ORG/app8-ios-cloud-sdk" --squash --delete-branch
check_main app8-ios-cloud-sdk
show app8-ios-cloud-sdk Sources/App8Cloud/Internal/SDKVersion.swift | grep -q "current = \"$V\"" || die "iOS cloud SDKVersion != $V"
tag_and_release app8-ios-cloud-sdk "App8Cloud (iOS)" "$NOTES"

say "5/5 app8-android-cloud-sdk (waits for the engine package to be published)"
run=""
for _ in $(seq 1 30); do # the tag push starts release.yml; give it a moment to appear
  run=$(gh run list -R "$ORG/app8-android-sdk" --workflow release.yml --branch "$V" -L 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
  [[ -n "$run" ]] && break; sleep 10
done
[[ -n "$run" ]] || die "no release.yml run for $V on app8-android-sdk"
gh run watch "$run" -R "$ORG/app8-android-sdk" --exit-status >/dev/null || die "Android engine release workflow failed: gh run view $run -R $ORG/app8-android-sdk"
tag_and_release app8-android-cloud-sdk "App8 Cloud (Android)" "$NOTES"

say "Done: $V on app8-dsl, both engines, both cloud SDKs"
