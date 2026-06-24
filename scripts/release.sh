#!/usr/bin/env bash
#
# release.sh — version, tag, and publish a GitHub Release for Bandwidth Monitor.
#
# Usage:
#   scripts/release.sh <marketing-version>   Cut a release: set MARKETING_VERSION, bump the
#                                            build number, regenerate, commit, tag, push, and
#                                            create a GitHub Release. e.g. scripts/release.sh 0.9.1
#
#   scripts/release.sh bump-build            Just increment CURRENT_PROJECT_VERSION (the build
#                                            number) for a new TestFlight/App Store upload of the
#                                            same marketing version — commit + push, no tag.
#
# Options:
#   --no-build   Skip the compile-check step (faster, but you're tagging unverified).
#
# Requires: git, xcodegen, gh (authenticated), Xcode.
set -euo pipefail

# --- locate repo root so the script works from anywhere -----------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT_YML="project.yml"
SCHEME="BandwidthMonitor"
DO_BUILD=1

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

# --- preflight: tools, repo state ---------------------------------------------------------------
for tool in git xcodegen gh; do
  command -v "$tool" >/dev/null 2>&1 || die "'$tool' is not installed or not on PATH"
done
gh auth status >/dev/null 2>&1 || die "gh is not authenticated — run 'gh auth login'"
[ -f "$PROJECT_YML" ] || die "can't find $PROJECT_YML (run from the repo, or via scripts/release.sh)"

# Refuse to run with a dirty tree: a release commit must contain only the version bump.
git diff --quiet && git diff --cached --quiet || \
  die "working tree has uncommitted changes — commit or stash them first"

current_marketing() { grep -E '^\s*MARKETING_VERSION:' "$PROJECT_YML" | sed -E 's/.*"([^"]*)".*/\1/'; }
current_build()     { grep -E '^\s*CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | sed -E 's/.*"([^"]*)".*/\1/'; }

set_marketing() { sed -i '' -E "s/(MARKETING_VERSION: )\"[^\"]*\"/\1\"$1\"/" "$PROJECT_YML"; }
set_build()     { sed -i '' -E "s/(CURRENT_PROJECT_VERSION: )\"[^\"]*\"/\1\"$1\"/" "$PROJECT_YML"; }

verify_build() {
  [ "$DO_BUILD" -eq 1 ] || { echo "==> skipping build check (--no-build)"; return; }
  echo "==> compile check (generic iOS Simulator)…"
  xcodebuild -project "$SCHEME.xcodeproj" -scheme "$SCHEME" -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/bm-release-check \
    build >/tmp/bm-release-check.log 2>&1 \
    || { tail -30 /tmp/bm-release-check.log; die "build failed — not releasing"; }
  echo "    build OK"
}

# --- parse args ---------------------------------------------------------------------------------
ARGS=()
for a in "$@"; do
  case "$a" in
    --no-build) DO_BUILD=0 ;;
    -*) die "unknown option: $a" ;;
    *) ARGS+=("$a") ;;
  esac
done
[ "${#ARGS[@]}" -ge 1 ] || die "usage: scripts/release.sh <marketing-version> | bump-build [--no-build]"
CMD="${ARGS[0]}"

# --- bump-build: new build of the same marketing version ----------------------------------------
if [ "$CMD" = "bump-build" ]; then
  NEW_BUILD=$(( $(current_build) + 1 ))
  echo "==> build number: $(current_build) -> $NEW_BUILD (marketing stays $(current_marketing))"
  set_build "$NEW_BUILD"
  xcodegen generate >/dev/null
  verify_build
  git add -A
  git commit -q -m "Bump build number to $NEW_BUILD"
  git push -q
  echo "==> done. Pushed build $NEW_BUILD."
  exit 0
fi

# --- release a marketing version ----------------------------------------------------------------
VERSION="$CMD"
echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' || die "version must be X.Y.Z (got '$VERSION')"
TAG="v$VERSION"
git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && die "tag $TAG already exists"

NEW_BUILD=$(( $(current_build) + 1 ))
echo "==> releasing $TAG (marketing $(current_marketing) -> $VERSION, build -> $NEW_BUILD)"

set_marketing "$VERSION"
set_build "$NEW_BUILD"
xcodegen generate >/dev/null
verify_build

git add -A
git commit -q -m "Release $TAG (build $NEW_BUILD)"
git tag -a "$TAG" -m "$TAG"
git push -q
git push -q origin "$TAG"

# --latest marks it the newest release; --generate-notes builds notes from commits since last tag.
gh release create "$TAG" --title "$TAG" --generate-notes --latest
echo "==> done. Released $TAG."
