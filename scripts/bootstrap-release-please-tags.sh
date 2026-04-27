#!/usr/bin/env bash
#
# Bootstrap the initial per-component tags used by Release Please.
#
# Creates `<component>/v1.0.0`, `<component>/v1.0`, and `<component>/v1`
# for every workflow and composite action tracked in
# `.github/release-please-manifest.json`, pointing at the current
# `origin/main` HEAD.
#
# Run this ONCE, immediately before merging the pull request that
# introduces Release Please. After that, every subsequent version bump
# and float update is handled automatically by the `Prepare release`
# workflow.

set -euo pipefail

COMPONENTS=(
  reusable-workflow-1
  reusable-workflow-2
  npm_test
)

echo "Fetching origin/main..."
git fetch origin main
SHA=$(git rev-parse origin/main)
echo "Target commit: ${SHA}"
echo

echo "Checking for pre-existing bootstrap tags..."
EXISTING=()
for C in "${COMPONENTS[@]}"; do
  for REF in "v1.0.0" "v1.0" "v1"; do
    if git rev-parse -q --verify "refs/tags/${C}/${REF}" >/dev/null 2>&1; then
      EXISTING+=("${C}/${REF}")
    fi
  done
done

if (( ${#EXISTING[@]} > 0 )); then
  echo "ERROR: the following tags already exist locally:" >&2
  printf '  %s\n' "${EXISTING[@]}" >&2
  echo >&2
  echo "Bootstrap has likely already been run. Aborting to avoid overwriting." >&2
  exit 1
fi

echo "Creating 9 tags (3 components x 3 refs)..."
for C in "${COMPONENTS[@]}"; do
  git tag "${C}/v1.0.0" "${SHA}"
  git tag "${C}/v1.0"   "${SHA}"
  git tag "${C}/v1"     "${SHA}"
done

echo "Pushing tags to origin..."
PUSH_ARGS=()
for C in "${COMPONENTS[@]}"; do
  PUSH_ARGS+=("${C}/v1.0.0" "${C}/v1.0" "${C}/v1")
done
git push origin "${PUSH_ARGS[@]}"

echo
echo "Done. You can now merge the Release Please pull request."
