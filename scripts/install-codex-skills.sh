#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf 'Usage: %s [target-git-checkout]\n' "${0##*/}"
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    usage
    exit 0
fi
if (( $# > 1 )); then
    usage >&2
    exit 2
fi

source_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
target_root=$(git -C "${1:-$source_root}" rev-parse --show-toplevel)
destination="$target_root/.agents/skills"

for directory in "$target_root/.agents" "$destination"; do
    if [[ -L "$directory" ]]; then
        printf 'Installation directory is a symlink: %s\n' "$directory" >&2
        exit 1
    fi
done

skills=()
for skill in "$source_root"/skills/*; do
    [[ -f "$skill/SKILL.md" ]] || continue
    skills+=("$skill")
done

conflicts=0
for skill in "${skills[@]}"; do
    link="$destination/${skill##*/}"
    if [[ -e "$link" || -L "$link" ]]; then
        if [[ ! -L "$link" || ! "$link" -ef "$skill" ]]; then
            printf 'Existing skill would be replaced: %s\n' "$link" >&2
            conflicts=1
        fi
    fi
done
(( conflicts == 0 )) || exit 1

mkdir -p -- "$destination"
for skill in "${skills[@]}"; do
    link="$destination/${skill##*/}"
    [[ -L "$link" && "$link" -ef "$skill" ]] && continue
    ln -s -n -- "$skill" "$link"
done
printf 'Installed %s ystack skills in %s\n' "${#skills[@]}" "$destination"
