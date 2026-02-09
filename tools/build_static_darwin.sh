#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET_ARCH="${TARGET_ARCH:-}"
if [[ -z "$TARGET_ARCH" ]]; then
  case "$(uname -m)" in
    arm64) TARGET_ARCH="arm64" ;;
    x86_64) TARGET_ARCH="x86_64" ;;
    *) TARGET_ARCH="$(uname -m)" ;;
  esac
fi

ARCH_FLAGS_STR=""
if [[ "$TARGET_ARCH" == "arm64" || "$TARGET_ARCH" == "x86_64" ]]; then
  ARCH_FLAGS_STR="-arch $TARGET_ARCH"
fi

OUTDIR="$ROOT_DIR/build/static/darwin-$TARGET_ARCH"
BUILD="$OUTDIR/.work"
SRC="$BUILD/src"
OBJ="$BUILD/obj"
mkdir -p "$SRC" "$OBJ" "$OUTDIR"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 2
  fi
}

for c in clang make ar ranlib curl tar python3 pkg-config; do
  need_cmd "$c"
done

OPENSSL_CFLAGS="${OPENSSL_CFLAGS:-}"
OPENSSL_LIBS="${OPENSSL_LIBS:-}"
OPENSSL_STATIC_LIBS=""
OPENSSL_PREFIX="${OPENSSL_PREFIX:-}"

if [[ -z "$OPENSSL_CFLAGS" || -z "$OPENSSL_LIBS" || -z "$OPENSSL_PREFIX" ]]; then
  if pkg-config --exists openssl; then
    OPENSSL_CFLAGS="${OPENSSL_CFLAGS:-$(pkg-config --cflags openssl)}"
    OPENSSL_LIBS="${OPENSSL_LIBS:-$(pkg-config --libs openssl)}"
    OPENSSL_PREFIX="${OPENSSL_PREFIX:-$(pkg-config --variable=prefix openssl 2>/dev/null || true)}"
  fi
fi

if [[ -z "$OPENSSL_PREFIX" && -z "$OPENSSL_CFLAGS" && -z "$OPENSSL_LIBS" ]]; then
  if command -v brew >/dev/null 2>&1; then
    for formula in openssl@3 openssl@1.1; do
      prefix="$(brew --prefix "$formula" 2>/dev/null || true)"
      if [[ -n "$prefix" ]]; then
        OPENSSL_PREFIX="$prefix"
        OPENSSL_CFLAGS="-I$OPENSSL_PREFIX/include"
        OPENSSL_LIBS="-L$OPENSSL_PREFIX/lib -lssl -lcrypto -lz"
        break
      fi
    done
  fi
fi

if [[ -z "$OPENSSL_CFLAGS" || -z "$OPENSSL_LIBS" ]]; then
  echo "OpenSSL not found. Install via Homebrew (openssl@3) or ensure pkg-config can find it." >&2
  exit 2
fi

check_arch_lib() {
  local lib="$1"
  if command -v lipo >/dev/null 2>&1; then
    if ! lipo -info "$lib" 2>/dev/null | grep -q "$TARGET_ARCH"; then
      echo "OpenSSL library $lib does not contain arch $TARGET_ARCH." >&2
      echo "Install OpenSSL for $TARGET_ARCH and retry." >&2
      exit 2
    fi
  fi
}

if [[ -n "$OPENSSL_PREFIX" && -f "$OPENSSL_PREFIX/lib/libssl.a" && -f "$OPENSSL_PREFIX/lib/libcrypto.a" ]]; then
  check_arch_lib "$OPENSSL_PREFIX/lib/libssl.a"
  check_arch_lib "$OPENSSL_PREFIX/lib/libcrypto.a"
  OPENSSL_STATIC_LIBS="$OPENSSL_PREFIX/lib/libssl.a $OPENSSL_PREFIX/lib/libcrypto.a"
elif [[ -n "$OPENSSL_PREFIX" && -f "$OPENSSL_PREFIX/lib/libssl.dylib" ]]; then
  check_arch_lib "$OPENSSL_PREFIX/lib/libssl.dylib"
fi

LUA_VER="5.1.5"
LUA_DIR="$SRC/lua-$LUA_VER"
if [[ ! -d "$LUA_DIR" ]]; then
  if [[ -n "${LUA_TARBALL:-}" ]]; then
    tar -xzf "$LUA_TARBALL" -C "$SRC"
  else
    if ! curl -L -o "$SRC/lua.tar.gz" "https://www.lua.org/ftp/lua-$LUA_VER.tar.gz"; then
      echo "Failed to download Lua sources. Provide LUA_TARBALL to a local lua-$LUA_VER.tar.gz." >&2
      exit 2
    fi
    tar -xzf "$SRC/lua.tar.gz" -C "$SRC"
  fi
fi

LUA_INC="$LUA_DIR/src"
LUA_LIB="$LUA_DIR/src/liblua.a"
if [[ ! -f "$LUA_LIB" ]]; then
  LUA_OBJ="$BUILD/lua-obj"
  mkdir -p "$LUA_OBJ"
  LUA_CFLAGS="-O2 -Wall -DLUA_USE_LINUX $ARCH_FLAGS_STR -I$LUA_INC"
  lua_core=(lapi lcode ldebug ldo ldump lfunc lgc llex lmem lobject lopcodes lparser lstate lstring ltable ltm lundump lvm lzio)
  lua_lib=(lauxlib lbaselib ldblib liolib lmathlib loslib ltablib lstrlib loadlib linit)
  for c in "${lua_core[@]}" "${lua_lib[@]}"; do
    clang $LUA_CFLAGS -c "$LUA_DIR/src/$c.c" -o "$LUA_OBJ/$c.o"
  done
  ar rcs "$LUA_LIB" "$LUA_OBJ"/*.o
  ranlib "$LUA_LIB"
fi

LUA_SOCKET_VER="3.1.0"
LUA_SEC_VER="1.3.2"

if [[ ! -d "$SRC/luasocket-$LUA_SOCKET_VER" ]]; then
  if [[ -n "${LUASOCKET_TARBALL:-}" ]]; then
    tar -xzf "$LUASOCKET_TARBALL" -C "$SRC"
  else
    if ! curl -L -o "$SRC/luasocket.tar.gz" "https://github.com/diegonehab/luasocket/archive/refs/tags/v${LUA_SOCKET_VER}.tar.gz"; then
      echo "Failed to download LuaSocket sources. Provide LUASOCKET_TARBALL to a local tarball." >&2
      exit 2
    fi
    tar -xzf "$SRC/luasocket.tar.gz" -C "$SRC"
  fi
fi

if [[ ! -d "$SRC/luasec-$LUA_SEC_VER" ]]; then
  if [[ -n "${LUASEC_TARBALL:-}" ]]; then
    tar -xzf "$LUASEC_TARBALL" -C "$SRC"
  else
    if ! curl -L -o "$SRC/luasec.tar.gz" "https://github.com/brunoos/luasec/archive/refs/tags/v${LUA_SEC_VER}.tar.gz"; then
      echo "Failed to download LuaSec sources. Provide LUASEC_TARBALL to a local tarball." >&2
      exit 2
    fi
    tar -xzf "$SRC/luasec.tar.gz" -C "$SRC"
  fi
fi

LUASOCKET_DIR="$SRC/luasocket-$LUA_SOCKET_VER"
LUASEC_DIR="$SRC/luasec-$LUA_SEC_VER"

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

ROOT_DIR="$ROOT_DIR" LUASOCKET_DIR="$LUASOCKET_DIR" LUASEC_DIR="$LUASEC_DIR" python3 - <<'PY'
import os

root = os.environ["ROOT_DIR"]
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

out_path = os.path.join(root, "build/static/darwin-" + os.environ.get("TARGET_ARCH", "arm64") + "/.work/bundle.lua")
with open(out_path, "w", encoding="utf-8") as f:
  f.write("\n".join(bundle))
PY

ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import os
root = os.environ["ROOT_DIR"]
path = os.path.join(root, "build/static/darwin-" + os.environ.get("TARGET_ARCH", "arm64") + "/.work/bundle.lua")
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
with open(os.path.join(root, "build/static/darwin-" + os.environ.get("TARGET_ARCH", "arm64") + "/.work/bundle.c"), "w", encoding="utf-8") as f:
  f.write("".join(out))
PY

CFLAGS="-O2 -I${LUA_INC} -I${LUASOCKET_DIR}/src -I${LUASEC_DIR}/src -DUNIX ${OPENSSL_CFLAGS} ${ARCH_FLAGS_STR}"

for src in "$LUASOCKET_DIR"/src/*.c; do
  base=$(basename "$src" .c)
  if [[ "$base" == "wsocket" ]]; then
    continue
  fi
  clang $CFLAGS -c "$src" -o "$OBJ/luasocket_$base.o"
done

for src in "$LUASEC_DIR"/src/*.c; do
  base=$(basename "$src" .c)
  clang $CFLAGS -I"$LUASEC_DIR"/src -c "$src" -o "$OBJ/luasec_$base.o"
done

clang -O2 $CFLAGS -c "$BUILD/main.c" -o "$OBJ/main.o"
clang -O2 $CFLAGS -c "$BUILD/bundle.c" -o "$OBJ/bundle.o"

OBJ_LIST=()
for obj in "$OBJ"/luasocket_*.o; do OBJ_LIST+=("$obj"); done
for obj in "$OBJ"/luasec_*.o; do OBJ_LIST+=("$obj"); done

LINK_LIBS=("$LUA_LIB")
if [[ -n "$OPENSSL_STATIC_LIBS" ]]; then
  LINK_LIBS+=($OPENSSL_STATIC_LIBS)
else
  LINK_LIBS+=($OPENSSL_LIBS)
fi
LINK_LIBS+=(-lm)

clang -O2 ${ARCH_FLAGS_STR} -Wl,-dead_strip -o "$OUTDIR/exaplus" \
  "$OBJ/main.o" "$OBJ/bundle.o" \
  "${OBJ_LIST[@]}" \
  "${LINK_LIBS[@]}"

echo "Built: $OUTDIR/exaplus"
echo "Linked libs:"
otool -L "$OUTDIR/exaplus"
