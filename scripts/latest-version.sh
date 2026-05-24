#!/usr/bin/env bash
set -euo pipefail

repo="${UPSTREAM_REPO:-https://github.com/gastownhall/beads.git}"

git ls-remote --tags --sort='v:refname' "$repo" 'refs/tags/v[0-9]*' |
    awk -F/ '{ print $NF }' |
    sed 's/\^{}//' |
    grep -E '^v[0-9]+[.][0-9]+[.][0-9]+$' |
    sort -Vu |
    tail -n 1 |
    sed 's/^v//'
