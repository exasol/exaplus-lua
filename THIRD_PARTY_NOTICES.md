# Third-Party Notices

This project bundles third‑party components under `vendor/`. The following
entries are based on upstream license statements and in‑tree headers.
Versions are noted where available.

## LuaSocket
- Files:
  - `vendor/lua/5.1/socket.lua`
  - `vendor/lua/5.1/socket/*`
  - `vendor/lua/5.1/ltn12.lua`
  - `vendor/lua/5.1/mime.lua`
  - `vendor/lua/5.1/liblua5.1-socket*.so`
  - `vendor/lua/5.1/liblua5.1-mime.so.2.0.0`
- Version: Unknown (bundled); in‑tree Lua modules report `LTN12 1.0.3` and `URL 1.0.3`.
- License: MIT (aka "Expat").
- Copyright: 1999-2013 Diego Nehab.
- Upstream: https://lunarmodules.github.io/luasocket/

## LuaSec
- Files:
  - `vendor/lua/5.1/ssl.lua`
  - `vendor/lua/5.1/ssl/*`
  - `vendor/lua/5.1/liblua5.1-sec.so.1.0.0`
- Version: 1.3.2 (from in‑tree headers).
- License: MIT (aka "Expat").
- Copyright: 2006-2023 Bruno Silvestre; 2009-2023 PUC-Rio (https.lua).
- Upstream: https://github.com/lunarmodules/luasec
- Notes: LuaSec is a binding to OpenSSL. If distributing binaries that link
  OpenSSL (statically or dynamically), ensure OpenSSL licensing obligations
  are met.

## OpenSSL (dependency)
- Status: Not bundled in this repo, but required by LuaSec at runtime.
- Action: Verify linkage and include required notices if distributing binaries.
  OpenSSL 3.0+ is Apache-2.0; OpenSSL <3.0 uses the OpenSSL/SSLeay license.

## Internal Modules
The following `lib/` modules are part of this repository and are assumed to be
original to this project unless noted otherwise. This includes the JSON, RSA,
and SHA1 implementations used by the client. If any of these files are derived
from external sources, add the appropriate notices and licenses here.

- `lib/base64.lua`
- `lib/bigint.lua`
- `lib/json.lua`
- `lib/lineedit.lua`
- `lib/rsa.lua`
- `lib/sha1.lua`
- `lib/util.lua`
- `lib/websocket.lua`
