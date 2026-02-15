#!/usr/bin/env bash
set -euo pipefail

# bump-chart-version.sh
# Detects modified charts in the staging area and auto patch-bumps their version.
# Intended to be called from a pre-commit hook.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the repo root
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Find charts with staged changes
changed_charts=()
while IFS= read -r file; do
  chart_dir=$(echo "$file" | grep -oE '^charts/[^/]+' || true)
  if [[ -n "$chart_dir" && -f "$REPO_ROOT/$chart_dir/Chart.yaml" ]]; then
    changed_charts+=("$chart_dir")
  fi
done < <(git diff --cached --name-only)

# Exit early if no charts changed
if [[ ${#changed_charts[@]} -eq 0 ]]; then
  exit 0
fi

# Deduplicate
changed_charts=($(printf '%s\n' "${changed_charts[@]}" | sort -u))

echo ""
echo -e "${CYAN}Auto patch-bumping charts with staged changes:${NC}"

for chart in "${changed_charts[@]}"; do
  chart_yaml="$REPO_ROOT/$chart/Chart.yaml"
  current_version=$(grep '^version:' "$chart_yaml" | awk '{print $2}')

  IFS='.' read -r major minor patch <<< "$current_version"
  new_version="$major.$minor.$((patch + 1))"

  sed -i '' "s/^version: .*/version: $new_version/" "$chart_yaml"
  git add "$chart_yaml"

  echo -e "  ${GREEN}$chart${NC}: ${YELLOW}v$current_version${NC} → ${GREEN}v$new_version${NC}"
done
echo ""
