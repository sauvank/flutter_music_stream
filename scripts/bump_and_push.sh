#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_dir"

if [[ -n $(git status --porcelain) ]]; then
  echo "Le dépôt doit être propre avant une release." >&2
  exit 1
fi

bump_type=${1:-patch}
current=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml)
version=${current%+*}
build=${current#*+}
IFS=. read -r major minor patch <<< "$version"

case "$bump_type" in
  patch) patch=$((patch + 1)) ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  major) major=$((major + 1)); minor=0; patch=0 ;;
  *) echo "Usage: $0 [patch|minor|major]" >&2; exit 64 ;;
esac

next="$major.$minor.$patch+$((build + 1))"
tag="v$major.$minor.$patch"
sed -i -E "s/^version:.*/version: $next/" pubspec.yaml
git add pubspec.yaml
git commit -m "chore(version): bump version to $next"
git tag -a "$tag" -m "Release $tag"
git push origin HEAD
git push origin "$tag"
