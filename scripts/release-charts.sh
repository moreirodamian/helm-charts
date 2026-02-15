#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
CHARTS_DIR="charts"
REPO_URL="https://moreirodamian.github.io/helm-charts/"
PACKAGES_DIR=".cr-release-packages"
DRY_RUN="${DRY_RUN:-0}"
CR_OWNER="${CR_OWNER:-}"
CR_GIT_REPO="${CR_GIT_REPO:-}"
CR_TOKEN="${CR_TOKEN:-}"

# ─── Data Structures ─────────────────────────────────────────────────────────
declare -A CHART_NAMES        # dir -> name
declare -A CHART_DIRS         # name -> dir
declare -A CHART_VERSIONS     # name -> version
declare -A INTERNAL_DEPS      # name -> "dep1 dep2 ..." (deduplicated)
declare -A REVERSE_DEPS       # name -> "dep1 dep2 ..."
declare -A RELEASE_SET        # name -> "direct" | "propagated"
declare -a MODIFIED_FILES=()  # Chart.yaml files modified by propagation
declare -A REPO_NAMES         # repo url -> helm repo alias
declare -a ALL_CHARTS=()      # all chart names
declare -a SORTED_RELEASES=() # topologically sorted release order

# ─── Logging ──────────────────────────────────────────────────────────────────
log()  { echo "==> $*"; }
info() { echo "    $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

# ─── Phase 1: Discovery ──────────────────────────────────────────────────────
discover_charts() {
    log "Phase 1: Discovering charts..."

    for chart_yaml in "$CHARTS_DIR"/*/Chart.yaml; do
        local dir
        dir=$(dirname "$chart_yaml")
        dir=$(basename "$dir")

        local name version
        name=$(yq '.name' "$chart_yaml")
        version=$(yq '.version' "$chart_yaml")

        CHART_NAMES[$dir]="$name"
        CHART_DIRS[$name]="$dir"
        CHART_VERSIONS[$name]="$version"
        ALL_CHARTS+=("$name")

        # Collect internal dependencies (deduplicated by dep name)
        local deps=""
        local dep_count
        dep_count=$(yq '(.dependencies // []) | length' "$chart_yaml")

        for ((i = 0; i < dep_count; i++)); do
            local dep_repo dep_name
            dep_repo=$(yq ".dependencies[$i].repository // \"\"" "$chart_yaml")
            dep_name=$(yq ".dependencies[$i].name" "$chart_yaml")

            if [[ "$dep_repo" == "$REPO_URL" ]]; then
                if [[ -z "$deps" ]]; then
                    deps="$dep_name"
                elif [[ ! " $deps " =~ " $dep_name " ]]; then
                    deps="$deps $dep_name"
                fi
            fi
        done

        INTERNAL_DEPS[$name]="$deps"
        info "$name ($version)  dir=$dir  deps=[$deps]"
    done

    # Build reverse-dependency map
    for name in "${ALL_CHARTS[@]}"; do
        for dep in ${INTERNAL_DEPS[$name]}; do
            local existing="${REVERSE_DEPS[$dep]:-}"
            if [[ -z "$existing" ]]; then
                REVERSE_DEPS[$dep]="$name"
            else
                REVERSE_DEPS[$dep]="$existing $name"
            fi
        done
    done

    log "Reverse dependencies:"
    for name in "${ALL_CHARTS[@]}"; do
        if [[ -n "${REVERSE_DEPS[$name]:-}" ]]; then
            info "$name <- [${REVERSE_DEPS[$name]}]"
        fi
    done
}

# ─── Phase 2: Change Detection ───────────────────────────────────────────────
detect_changes() {
    log "Phase 2: Detecting unreleased charts..."

    for name in "${ALL_CHARTS[@]}"; do
        local version="${CHART_VERSIONS[$name]}"
        local tag="${name}-${version}"

        if git rev-parse "$tag" >/dev/null 2>&1; then
            info "$name ($version): tag exists, skipping"
        else
            info "$name ($version): NEW - no tag found"
            RELEASE_SET[$name]="direct"
        fi
    done

    if [[ ${#RELEASE_SET[@]} -eq 0 ]]; then
        log "No charts to release. Done."
        exit 0
    fi

    log "Directly changed: ${!RELEASE_SET[*]}"
}

# ─── Phase 3: Auto-Propagation ───────────────────────────────────────────────
bump_patch() {
    local version="$1"
    local major minor patch
    IFS='.' read -r major minor patch <<< "$version"
    echo "$major.$minor.$((patch + 1))"
}

update_constraints() {
    local dependent="$1"
    local dep_name="$2"
    local chart_yaml="$CHARTS_DIR/${CHART_DIRS[$dependent]}/Chart.yaml"
    local new_dep_version="${CHART_VERSIONS[$dep_name]}"

    # Extract major.minor from the dependency's new version
    local new_major new_minor
    IFS='.' read -r new_major new_minor _ <<< "$new_dep_version"
    local new_constraint="${new_major}.${new_minor}.*"

    # Update every dependency entry that references dep_name from self repo
    local dep_count
    dep_count=$(yq '(.dependencies // []) | length' "$chart_yaml")

    for ((i = 0; i < dep_count; i++)); do
        local entry_name entry_repo entry_version
        entry_name=$(yq ".dependencies[$i].name" "$chart_yaml")
        entry_repo=$(yq ".dependencies[$i].repository // \"\"" "$chart_yaml")
        entry_version=$(yq ".dependencies[$i].version" "$chart_yaml")

        if [[ "$entry_name" == "$dep_name" ]] && [[ "$entry_repo" == "$REPO_URL" ]]; then
            local cur_major cur_minor
            IFS='.' read -r cur_major cur_minor _ <<< "$entry_version"

            if [[ "$cur_major" != "$new_major" ]] || [[ "$cur_minor" != "$new_minor" ]]; then
                info "  constraint $dep_name: $entry_version -> $new_constraint"
                yq -i ".dependencies[$i].version = \"$new_constraint\"" "$chart_yaml"
            fi
        fi
    done
}

propagate_changes() {
    log "Phase 3: Propagating changes to dependents..."

    # BFS queue seeded with directly changed charts
    local -a queue=()
    for name in "${!RELEASE_SET[@]}"; do
        queue+=("$name")
    done

    local idx=0
    while [[ $idx -lt ${#queue[@]} ]]; do
        local current="${queue[$idx]}"
        idx=$((idx + 1))

        for dependent in ${REVERSE_DEPS[$current]:-}; do
            # Skip if already in the release set
            [[ -n "${RELEASE_SET[$dependent]+x}" ]] && continue

            local dep_dir="${CHART_DIRS[$dependent]}"
            local dep_chart="$CHARTS_DIR/$dep_dir/Chart.yaml"
            local old_version="${CHART_VERSIONS[$dependent]}"
            local new_version
            new_version=$(bump_patch "$old_version")

            info "Bumping $dependent: $old_version -> $new_version (triggered by $current)"

            # Update in-memory version
            CHART_VERSIONS[$dependent]="$new_version"

            if [[ "$DRY_RUN" != "1" ]]; then
                yq -i ".version = \"$new_version\"" "$dep_chart"
                update_constraints "$dependent" "$current"
            fi

            RELEASE_SET[$dependent]="propagated"
            MODIFIED_FILES+=("$dep_chart")
            queue+=("$dependent")
        done
    done

    # Handle cascading constraint updates for propagated charts that are
    # also dependencies of other propagated charts already in the set.
    if [[ "$DRY_RUN" != "1" ]]; then
        for name in "${!RELEASE_SET[@]}"; do
            [[ "${RELEASE_SET[$name]}" != "propagated" ]] && continue
            for dependent in ${REVERSE_DEPS[$name]:-}; do
                [[ -n "${RELEASE_SET[$dependent]+x}" ]] || continue
                update_constraints "$dependent" "$name"
            done
        done
    fi

    log "Release set (${#RELEASE_SET[@]} charts): ${!RELEASE_SET[*]}"
}

# ─── Phase 4: Topological Sort (Kahn's algorithm) ────────────────────────────
topological_sort() {
    log "Phase 4: Topological sort of release set..."

    # Build in-degree map scoped to the release set
    declare -A in_degree
    for name in "${!RELEASE_SET[@]}"; do
        in_degree[$name]=0
    done

    for name in "${!RELEASE_SET[@]}"; do
        for dep in ${INTERNAL_DEPS[$name]}; do
            if [[ -n "${RELEASE_SET[$dep]+x}" ]]; then
                in_degree[$name]=$(( ${in_degree[$name]} + 1 ))
            fi
        done
    done

    # Kahn's algorithm
    local -a queue=()
    for name in "${!RELEASE_SET[@]}"; do
        if [[ ${in_degree[$name]} -eq 0 ]]; then
            queue+=("$name")
        fi
    done

    local head=0
    while [[ $head -lt ${#queue[@]} ]]; do
        local current="${queue[$head]}"
        head=$((head + 1))
        SORTED_RELEASES+=("$current")

        for dependent in ${REVERSE_DEPS[$current]:-}; do
            if [[ -n "${RELEASE_SET[$dependent]+x}" ]]; then
                in_degree[$dependent]=$(( ${in_degree[$dependent]} - 1 ))
                if [[ ${in_degree[$dependent]} -eq 0 ]]; then
                    queue+=("$dependent")
                fi
            fi
        done
    done

    if [[ ${#SORTED_RELEASES[@]} -ne ${#RELEASE_SET[@]} ]]; then
        die "Cycle detected in dependency graph! Sorted ${#SORTED_RELEASES[@]} of ${#RELEASE_SET[@]} charts."
    fi

    log "Release order:"
    local pos=1
    for name in "${SORTED_RELEASES[@]}"; do
        local reason="${RELEASE_SET[$name]}"
        info "$pos. $name (${CHART_VERSIONS[$name]}) [$reason]"
        pos=$((pos + 1))
    done
}

# ─── Phase 5: Ordered Packaging ──────────────────────────────────────────────
add_helm_repos() {
    local -A seen_repos
    local counter=0

    for name in "${SORTED_RELEASES[@]}"; do
        local dir="${CHART_DIRS[$name]}"
        local chart_yaml="$CHARTS_DIR/$dir/Chart.yaml"
        local dep_count
        dep_count=$(yq '(.dependencies // []) | length' "$chart_yaml")

        for ((i = 0; i < dep_count; i++)); do
            local repo_url
            repo_url=$(yq ".dependencies[$i].repository // \"\"" "$chart_yaml")

            if [[ -n "$repo_url" ]] && [[ -z "${seen_repos[$repo_url]+x}" ]]; then
                local alias="repo-${counter}"
                info "Adding repo $alias -> $repo_url"
                helm repo add "$alias" "$repo_url" --force-update
                REPO_NAMES[$repo_url]="$alias"
                seen_repos[$repo_url]=1
                counter=$((counter + 1))
            fi
        done
    done

    if [[ ${#seen_repos[@]} -gt 0 ]]; then
        helm repo update
    fi
}

resolve_dependencies() {
    local chart_name="$1"
    local chart_dir="$2"
    local chart_yaml="$CHARTS_DIR/$chart_dir/Chart.yaml"
    local dep_count
    dep_count=$(yq '(.dependencies // []) | length' "$chart_yaml")

    [[ "$dep_count" -eq 0 ]] && return 0

    mkdir -p "$CHARTS_DIR/$chart_dir/charts"
    # Clean stale .tgz files (directories like local subcharts are untouched)
    rm -f "$CHARTS_DIR/$chart_dir/charts/"*.tgz 2>/dev/null || true

    for ((i = 0; i < dep_count; i++)); do
        local dep_name dep_version dep_repo
        dep_name=$(yq ".dependencies[$i].name" "$chart_yaml")
        dep_version=$(yq ".dependencies[$i].version" "$chart_yaml")
        dep_repo=$(yq ".dependencies[$i].repository // \"\"" "$chart_yaml")

        # Local subchart (no repo) – already present as a directory
        if [[ -z "$dep_repo" ]]; then
            info "  $dep_name: local subchart, skip"
            continue
        fi

        # Internal dependency that was just packaged in this run
        if [[ "$dep_repo" == "$REPO_URL" ]] && [[ -n "${RELEASE_SET[$dep_name]+x}" ]]; then
            local pkg_version="${CHART_VERSIONS[$dep_name]}"
            info "  $dep_name: copy from packages ($pkg_version)"
            cp "$PACKAGES_DIR/$dep_name-$pkg_version.tgz" "$CHARTS_DIR/$chart_dir/charts/"
            continue
        fi

        # External dependency or unchanged internal dependency – helm pull
        local repo_alias="${REPO_NAMES[$dep_repo]}"
        info "  $dep_name: pull $repo_alias/$dep_name ($dep_version)"
        helm pull "$repo_alias/$dep_name" --version "$dep_version" \
            -d "$CHARTS_DIR/$chart_dir/charts/"
    done
}

package_charts() {
    log "Phase 5: Packaging charts in dependency order..."

    mkdir -p "$PACKAGES_DIR"
    add_helm_repos

    for name in "${SORTED_RELEASES[@]}"; do
        local dir="${CHART_DIRS[$name]}"
        log "  Packaging $name (${CHART_VERSIONS[$name]})..."

        resolve_dependencies "$name" "$dir"
        helm package "$CHARTS_DIR/$dir" -d "$PACKAGES_DIR"

        # Clean up downloaded .tgz so they are not committed
        rm -f "$CHARTS_DIR/$dir/charts/"*.tgz 2>/dev/null || true
    done
}

# ─── Phase 6: Upload & Index ─────────────────────────────────────────────────
upload_and_index() {
    log "Phase 6: Uploading packages and updating index..."

    cr upload --skip-existing \
        -o "$CR_OWNER" \
        -r "$CR_GIT_REPO" \
        --token "$CR_TOKEN" \
        --package-path "$PACKAGES_DIR"

    # Clean stale worktree left by cr upload before indexing
    rm -rf .cr-index

    cr index \
        -o "$CR_OWNER" \
        -r "$CR_GIT_REPO" \
        --token "$CR_TOKEN" \
        --package-path "$PACKAGES_DIR" \
        --index-path ".cr-index/index.yaml" \
        --push
}

# ─── Phase 7: Auto-Bump Commit ───────────────────────────────────────────────
commit_bumps() {
    if [[ ${#MODIFIED_FILES[@]} -eq 0 ]]; then
        log "Phase 7: No auto-bump commits needed."
        return
    fi

    log "Phase 7: Committing auto-bumped Chart.yaml files..."
    git add "${MODIFIED_FILES[@]}"
    git commit -m "chore: auto-bump dependent chart versions [skip ci]"
    git push origin main
}

# ─── Preflight Checks ────────────────────────────────────────────────────────
preflight() {
    command -v yq >/dev/null 2>&1 || die "yq is required but not installed"
    command -v helm >/dev/null 2>&1 || die "helm is required but not installed"
    [[ -d "$CHARTS_DIR" ]] || die "Charts directory '$CHARTS_DIR' not found"

    if [[ "$DRY_RUN" != "1" ]]; then
        command -v cr >/dev/null 2>&1 || die "cr (chart-releaser) is required but not installed"
        [[ -n "$CR_OWNER" ]]    || die "CR_OWNER is not set"
        [[ -n "$CR_GIT_REPO" ]] || die "CR_GIT_REPO is not set"
        [[ -n "$CR_TOKEN" ]]    || die "CR_TOKEN is not set"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    log "Starting ordered chart release..."
    [[ "$DRY_RUN" == "1" ]] && log "(DRY RUN – no packages, uploads, or commits)"

    preflight
    discover_charts
    detect_changes
    propagate_changes
    topological_sort

    if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY RUN complete. ${#SORTED_RELEASES[@]} chart(s) would be released."
        if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
            log "Would commit changes to:"
            printf '    %s\n' "${MODIFIED_FILES[@]}"
        fi
        exit 0
    fi

    package_charts
    upload_and_index
    commit_bumps

    log "Done! Released ${#SORTED_RELEASES[@]} chart(s)."
}

main "$@"
