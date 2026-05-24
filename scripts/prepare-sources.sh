#!/usr/bin/env bash
set -euo pipefail

repo="${UPSTREAM_REPO:-https://github.com/gastownhall/beads.git}"
spec="beads.spec"
sources_dir=".rpmbuild/SOURCES"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --spec)
            spec="$2"
            shift 2
            ;;
        --sources-dir)
            sources_dir="$2"
            shift 2
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            exit 1
            ;;
    esac
done

version="$(awk '$1 == "Version:" { print $2; exit }' "$spec")"
go_version="$(awk '$1 == "%global" && $2 == "go_version" { print $3; exit }' "$spec")"

if [[ -z "$version" || -z "$go_version" ]]; then
    printf 'Could not read Version or go_version from %s\n' "$spec" >&2
    exit 1
fi

mkdir -p "$sources_dir"

workdir="$(mktemp -d)"
cleanup() {
    if [[ -d "$workdir" ]]; then
        chmod -R u+w "$workdir" 2>/dev/null || true
        rm -rf "$workdir"
    fi
}
trap cleanup EXIT

download() {
    local url="$1"
    local dest="$2"
    local tmp="${dest}.tmp"

    if [[ -s "$dest" ]]; then
        return 0
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 -o "$tmp" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$tmp" "$url"
    else
        printf 'Neither curl nor wget is available for downloading %s\n' "$url" >&2
        exit 1
    fi

    mv "$tmp" "$dest"
}

go_tarball="${sources_dir}/go${go_version}.linux-amd64.tar.gz"
source_tarball="${sources_dir}/beads-${version}-vendor.tar.gz"

download "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz" "$go_tarball"

case "$(uname -m)" in
    x86_64)
        host_go_arch="amd64"
        ;;
    aarch64|arm64)
        host_go_arch="arm64"
        ;;
    *)
        printf 'Unsupported source-build architecture for Go toolchain: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

host_go_tarball="$go_tarball"
if [[ "$host_go_arch" != "amd64" ]]; then
    host_go_tarball="${workdir}/go${go_version}.linux-${host_go_arch}.tar.gz"
    download "https://go.dev/dl/go${go_version}.linux-${host_go_arch}.tar.gz" "$host_go_tarball"
fi

srcdir="${workdir}/beads-${version}"
git clone --depth 1 --branch "v${version}" "$repo" "$srcdir"

actual_go_version="$(sed -n 's/^go //p' "$srcdir/go.mod" | head -n 1)"
if [[ "$actual_go_version" != "$go_version" ]]; then
    printf 'Spec Go version %s does not match upstream go.mod %s\n' "$go_version" "$actual_go_version" >&2
    printf 'Run ./scripts/update-version.sh %s and retry.\n' "$version" >&2
    exit 1
fi

epoch="$(git -C "$srcdir" log -1 --format=%ct)"
rm -rf "$srcdir/.git"

goroot="${workdir}/go"
mkdir -p "$goroot"
tar xzf "$host_go_tarball" -C "$goroot" --strip-components=1

(
    cd "$srcdir"
    export GOROOT="$goroot"
    export PATH="${GOROOT}/bin:${PATH}"
    export GOTOOLCHAIN=local
    export GOPATH="${workdir}/gopath"
    export GOMODCACHE="${workdir}/gomodcache"
    go mod vendor
)

rm -f "$source_tarball"
tar --sort=name \
    --mtime="@${epoch}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -czf "$source_tarball" \
    -C "$workdir" "beads-${version}"

sha256sum "$source_tarball" "$go_tarball"
