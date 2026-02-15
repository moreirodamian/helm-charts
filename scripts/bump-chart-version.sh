#!/usr/bin/env bash
set -euo pipefail

# bump-chart-version.sh
# Detects modified charts in the staging area and prompts for version bump type.
# Intended to be called from a pre-commit hook.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the repo root
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Find charts with staged changes (excluding Chart.yaml itself to avoid loops)
changed_charts=()
while IFS= read -r file; do
  # Extract chart directory (charts/CHARTNAME)
  chart_dir=$(echo "$file" | grep -oE '^charts/[^/]+' || true)
  if [[ -n "$chart_dir" && -f "$REPO_ROOT/$chart_dir/Chart.yaml" ]]; then
    # Skip if the only change is Chart.yaml (avoid bump loop)
    changed_charts+=("$chart_dir")
  fi
done < <(git diff --cached --name-only)

# Deduplicate
changed_charts=($(printf '%s\n' "${changed_charts[@]}" | sort -u))

if [[ ${#changed_charts[@]} -eq 0 ]]; then
  exit 0
fi

echo ""
echo -e "${CYAN}Charts with staged changes detected:${NC}"
for chart in "${changed_charts[@]}"; do
  current_version=$(grep '^version:' "$REPO_ROOT/$chart/Chart.yaml" | awk '{print $2}')
  echo -e "  ${GREEN}$chart${NC} (current: ${YELLOW}v$current_version${NC})"
done
echo ""

for chart in "${changed_charts[@]}"; do
  chart_yaml="$REPO_ROOT/$chart/Chart.yaml"
  current_version=$(grep '^version:' "$chart_yaml" | awk '{print $2}')

  IFS='.' read -r major minor patch <<< "$current_version"

  next_patch="$major.$minor.$((patch + 1))"
  next_minor="$major.$((minor + 1)).0"
  next_major="$((major + 1)).0.0"

  echo -e "${CYAN}$chart${NC} (v$current_version):"
  echo -e "  ${GREEN}1)${NC} patch  → v$next_patch"
  echo -e "  ${GREEN}2)${NC} minor  → v$next_minor"
  echo -e "  ${GREEN}3)${NC} major  → v$next_major"
  echo -e "  ${GREEN}s)${NC} skip   → no bump"

  # Read from terminal (not stdin, which might be redirected)
  read -r -p "  Select [1/2/3/s] (default: 1): " choice < /dev/tty

  case "${choice:-1}" in
    1|patch)
      new_version="$next_patch"
      ;;
    2|minor)
      new_version="$next_minor"
      ;;
    3|major)
      new_version="$next_major"
      ;;
    s|skip)
      echo -e "  ${YELLOW}Skipped${NC}"
      echo ""
      continue
      ;;
    *)
      echo -e "  ${YELLOW}Invalid choice, defaulting to patch${NC}"
      new_version="$next_patch"
      ;;
  esac

  # Update Chart.yaml version
  sed -i '' "s/^version: .*/version: $new_version/" "$chart_yaml"

  # Re-add Chart.yaml to staging
  git add "$chart_yaml"

  echo -e "  ${GREEN}Bumped to v$new_version${NC}"
  echo ""
done
