#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTDIR="$ROOT_DIR/build/sources"

LUA_VER="${LUA_VER:-5.1.5}"
LUASOCKET_VER="${LUASOCKET_VER:-3.1.0}"
LUASEC_VER="${LUASEC_VER:-1.3.2}"

mkdir -p "$OUTDIR"

fetch() {
  local url="$1"
  local out="$2"
  if [[ -f "$out" ]]; then
    echo "Using cached: $out"
    return 0
  fi
  curl -L -o "$out" "$url"
}

fetch "https://www.lua.org/ftp/lua-${LUA_VER}.tar.gz" \
  "$OUTDIR/lua-${LUA_VER}.tar.gz"
fetch "https://github.com/diegonehab/luasocket/archive/refs/tags/v${LUASOCKET_VER}.tar.gz" \
  "$OUTDIR/luasocket-${LUASOCKET_VER}.tar.gz"
fetch "https://github.com/brunoos/luasec/archive/refs/tags/v${LUASEC_VER}.tar.gz" \
  "$OUTDIR/luasec-${LUASEC_VER}.tar.gz"

tar -xzf "$OUTDIR/lua-${LUA_VER}.tar.gz" -C "$OUTDIR"
tar -xzf "$OUTDIR/luasocket-${LUASOCKET_VER}.tar.gz" -C "$OUTDIR"
tar -xzf "$OUTDIR/luasec-${LUASEC_VER}.tar.gz" -C "$OUTDIR"

echo "Sources unpacked to: $OUTDIR"
