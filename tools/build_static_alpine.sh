#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="alpine:3.19"
PODMAN_OPTS=()

podman_ok() { command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; }
docker_ok() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

if podman_ok; then
  RUNTIME="podman"
  RUN_ID="$$"
  podman_has_opt() { podman --help 2>&1 | grep -q -- "$1"; }
  if podman_has_opt --root; then
    PODMAN_OPTS+=(--root "/tmp/podman-root-$RUN_ID")
  fi
  if podman_has_opt --runroot; then
    PODMAN_OPTS+=(--runroot "/tmp/podman-runroot-$RUN_ID")
  fi
  if podman_has_opt --tmpdir; then
    PODMAN_OPTS+=(--tmpdir "/tmp/podman-tmp-$RUN_ID")
  fi
  if podman_has_opt --storage-driver; then
    PODMAN_OPTS+=(--storage-driver=vfs)
  fi
  if podman_has_opt --events-backend; then
    PODMAN_OPTS+=(--events-backend=file)
  fi
  if podman_has_opt --cgroup-manager; then
    PODMAN_OPTS+=(--cgroup-manager=cgroupfs)
  fi
  export XDG_RUNTIME_DIR="/tmp/podman-runtime"
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
elif docker_ok; then
  RUNTIME="docker"
else
  if command -v podman >/dev/null 2>&1; then
    echo "Podman is installed but not running." >&2
    echo "Start Podman with: podman machine init && podman machine start" >&2
  fi
  if command -v docker >/dev/null 2>&1; then
    echo "Docker is installed but not running." >&2
    echo "Start Docker Desktop (or your Docker daemon) and retry." >&2
  fi
  if ! command -v podman >/dev/null 2>&1 && ! command -v docker >/dev/null 2>&1; then
    echo "Neither podman nor docker found" >&2
  fi
  exit 1
fi

RUN_OPTS=(-i)
if [ "$RUNTIME" = "podman" ]; then
  if podman run --help 2>&1 | grep -q -- "--rm"; then
    RUN_OPTS=(--rm "${RUN_OPTS[@]}")
  fi
else
  RUN_OPTS=(--rm "${RUN_OPTS[@]}")
fi

CMD=("$RUNTIME")
if [ "${#PODMAN_OPTS[@]}" -gt 0 ]; then
  CMD+=("${PODMAN_OPTS[@]}")
fi
CMD+=(run "${RUN_OPTS[@]}" -v "$ROOT_DIR:/work" -w /work "$IMAGE" /bin/sh -s)
exec "${CMD[@]}" <<'INNER'
set -eu

apk add --no-cache build-base curl tar python3 lua5.1-dev lua5.1 openssl-dev openssl-libs-static pkgconf

ROOT="/work"
if [ -z "${TARGET_ARCH:-}" ]; then
  case "$(uname -m)" in
    x86_64|amd64) TARGET_ARCH="x86_64" ;;
    i386|i686) TARGET_ARCH="x86" ;;
    aarch64|arm64) TARGET_ARCH="aarch64" ;;
    armv7l) TARGET_ARCH="armv7l" ;;
    *) TARGET_ARCH="$(uname -m)" ;;
  esac
fi
export TARGET_ARCH
OUTDIR="$ROOT/build/static/linux-$TARGET_ARCH"
BUILD="$OUTDIR/.work"
SRC="$BUILD/src"
OBJ="$BUILD/obj"
mkdir -p "$SRC" "$OBJ" "$OUTDIR"

LUA_SOCKET_VER="3.1.0"
LUA_SEC_VER="1.3.2"

if [ ! -d "$SRC/luasocket-$LUA_SOCKET_VER" ]; then
  curl -L -o "$SRC/luasocket.tar.gz" "https://github.com/diegonehab/luasocket/archive/refs/tags/v${LUA_SOCKET_VER}.tar.gz"
  tar -xzf "$SRC/luasocket.tar.gz" -C "$SRC"
fi

if [ ! -d "$SRC/luasec-$LUA_SEC_VER" ]; then
  curl -L -o "$SRC/luasec.tar.gz" "https://github.com/brunoos/luasec/archive/refs/tags/v${LUA_SEC_VER}.tar.gz"
  tar -xzf "$SRC/luasec.tar.gz" -C "$SRC"
fi

LUASOCKET_DIR="$SRC/luasocket-$LUA_SOCKET_VER"
LUASEC_DIR="$SRC/luasec-$LUA_SEC_VER"
LUA_INC="/usr/include/lua5.1"

cat > "$BUILD/main.c" <<'C'
#include <stdio.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

extern int luaopen_socket_core(lua_State *L);
extern int luaopen_mime_core(lua_State *L);
extern int luaopen_ssl_core(lua_State *L);
extern int luaopen_ssl_context(lua_State *L);
extern int luaopen_ssl_x509(lua_State *L);
extern int luaopen_ssl_config(lua_State *L);

extern const unsigned char bundle_lua[];
extern const unsigned int bundle_lua_len;

static void preload(lua_State *L, const char *name, lua_CFunction fn) {
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "preload");
  lua_pushcfunction(L, fn);
  lua_setfield(L, -2, name);
  lua_pop(L, 2);
}

int main(int argc, char **argv) {
  lua_State *L = luaL_newstate();
  if (!L) {
    fprintf(stderr, "failed to create lua state\n");
    return 1;
  }
  luaL_openlibs(L);

  preload(L, "socket.core", luaopen_socket_core);
  preload(L, "mime.core", luaopen_mime_core);
  preload(L, "ssl.core", luaopen_ssl_core);
  preload(L, "ssl.context", luaopen_ssl_context);
  preload(L, "ssl.x509", luaopen_ssl_x509);
  preload(L, "ssl.config", luaopen_ssl_config);

  lua_newtable(L);
  for (int i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i);
  }
  lua_setglobal(L, "arg");

  if (luaL_loadbuffer(L, (const char *)bundle_lua, bundle_lua_len, "@bundle") != 0) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }
  if (lua_pcall(L, 0, 0, 0) != 0) {
    fprintf(stderr, "%s\n", lua_tostring(L, -1));
    lua_close(L);
    return 1;
  }

  lua_close(L);
  return 0;
}
C

OUTDIR="$OUTDIR" LUASOCKET_DIR="$LUASOCKET_DIR" LUASEC_DIR="$LUASEC_DIR" python3 - <<'PY'
import os

root = "/work"
outdir = os.environ["OUTDIR"]
luasocket_dir = os.environ.get("LUASOCKET_DIR", "")
luasec_dir = os.environ.get("LUASEC_DIR", "")

modules = {
  "base64": "lib/base64.lua",
  "bigint": "lib/bigint.lua",
  "json": "lib/json.lua",
  "lineedit": "lib/lineedit.lua",
  "rsa": "lib/rsa.lua",
  "sha1": "lib/sha1.lua",
  "util": "lib/util.lua",
  "websocket": "lib/websocket.lua",
}

def read(path):
  with open(os.path.join(root, path), "r", encoding="utf-8") as f:
    return f.read()

def add_tree(base_dir, prefix=""):
  if not base_dir or not os.path.isdir(base_dir):
    return
  for dirpath, _, filenames in os.walk(base_dir):
    for fname in filenames:
      if not fname.endswith(".lua"):
        continue
      full = os.path.join(dirpath, fname)
      rel = os.path.relpath(full, base_dir).replace(os.sep, "/")
      mod = rel[:-4].replace("/", ".")
      if prefix:
        mod = prefix + "." + mod if mod else prefix
      modules[mod] = os.path.relpath(full, root)

def lua_long_bracket(s):
  eq = 1
  while ("]" + ("=" * eq) + "]") in s:
    eq += 1
  return "[" + ("=" * eq) + "[\n" + s + "]" + ("=" * eq) + "]"

add_tree(os.path.join(luasocket_dir, "src"), "")
add_tree(os.path.join(luasec_dir, "src"), "")

bundle = []
bundle.append("local function _preload(name, src)")
bundle.append("  package.preload[name] = function()")
bundle.append("    local f, err = loadstring(src, '@' .. name)")
bundle.append("    if not f then error(err) end")
bundle.append("    return f()")
bundle.append("  end")
bundle.append("end")
bundle.append("local sources = {}")
for name, path in modules.items():
  src = read(path)
  bundle.append("sources[%s] = %s" % (repr(name), lua_long_bracket(src)))
bundle.append("for name, src in pairs(sources) do _preload(name, src) end")
main_src = read("exaplus")
if main_src.startswith("#!"):
  main_src = "\n".join(main_src.splitlines()[1:]) + "\n"
bundle.append("local main_src = %s" % lua_long_bracket(main_src))
bundle.append("local f, err = loadstring(main_src, '@exaplus')")
bundle.append("if not f then error(err) end")
bundle.append("return f()")

out_path = os.path.join(outdir, ".work", "bundle.lua")
with open(out_path, "w", encoding="utf-8") as f:
  f.write("\n".join(bundle))
PY

OUTDIR="$OUTDIR" python3 - <<'PY'
import os
outdir = os.environ["OUTDIR"]
path = os.path.join(outdir, ".work", "bundle.lua")
with open(path, "rb") as f:
  data = f.read()
out = []
out.append("const unsigned char bundle_lua[] = {")
for i, b in enumerate(data):
  if i % 12 == 0:
    out.append("\n ")
  out.append(" %d," % b)
out.append("\n};\n")
out.append("const unsigned int bundle_lua_len = %d;\n" % len(data))
with open(os.path.join(outdir, ".work", "bundle.c"), "w", encoding="utf-8") as f:
  f.write("".join(out))
PY

CFLAGS="-O2 -I${LUA_INC} -I${LUASOCKET_DIR}/src -I${LUASEC_DIR}/src -DUNIX"

for src in "$LUASOCKET_DIR"/src/*.c; do
  base=$(basename "$src" .c)
  if [ "$base" = "wsocket" ]; then
    continue
  fi
  gcc $CFLAGS -c "$src" -o "$OBJ/luasocket_$base.o"
done

for src in "$LUASEC_DIR"/src/*.c; do
  base=$(basename "$src" .c)
  gcc $CFLAGS -I"$LUASEC_DIR"/src -c "$src" -o "$OBJ/luasec_$base.o"
done

gcc -O2 -c "$BUILD/main.c" -o "$OBJ/main.o"
gcc -O2 -c "$BUILD/bundle.c" -o "$OBJ/bundle.o"

SSL_LIBS="$(pkg-config --static --libs openssl 2>/dev/null || echo "-lssl -lcrypto -lz")"
LUA_LIBS="$(pkg-config --static --libs lua5.1 2>/dev/null || echo "-llua5.1")"

OBJ_LIST=""
for obj in "$OBJ"/luasocket_*.o; do OBJ_LIST="$OBJ_LIST $obj"; done
for obj in "$OBJ"/luasec_*.o; do OBJ_LIST="$OBJ_LIST $obj"; done

gcc -static -O2 -s -o "$OUTDIR/exaplus" \
  "$OBJ/main.o" "$OBJ/bundle.o" \
  $OBJ_LIST \
  -Wl,--start-group $LUA_LIBS $SSL_LIBS -lm -ldl -pthread -Wl,--end-group

echo "Built: $OUTDIR/exaplus"
INNER
