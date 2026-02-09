# EXAplusLua (minimal)

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A minimal Lua-based console client for Exasol WebSocket API v5. This is a simplified replacement for `Console/exaplus` with a reduced CLI.

## Requirements

- Lua 5.1 (invoked as `lua` or `lua5.1`)
- OpenSSL (required by LuaSec)

## Installation

This repo ships a single script (`exaplus`) plus bundled Lua modules under `lib/` and `vendor/`.

- Linux x86_64: you can run `./exaplus` directly (bundled LuaSocket/LuaSec binaries are included).
- Other platforms: rebuild LuaSocket/LuaSec for your platform or use system packages and set `LUA_PATH`/`LUA_CPATH` accordingly.

The bundled native modules are convenience builds and are not produced by CI.
If you need provenance or different platforms, rebuild them from upstream sources.

## Supported Platforms

- Linux x86_64 with the bundled native LuaSocket/LuaSec modules.
- Other platforms are untested and require rebuilding the native modules.

## Usage

```
./exaplus -c localhost/<fingerprint>:8563 -u sys -p exasol
./exaplus -c localhost/nocertcheck:8563 -u sys -p exasol
./exaplus -c localhost:8563/nocertcheck -u sys -p exasol
./exaplus -c localhost/<fingerprint>:8563 -u sys -sql "SELECT 1;"
./exaplus -c n11,n12,n13/nocertcheck:8563 -u sys -p exasol
```

Examples use the default `sys`/`exasol` credentials for a local instance; adjust
for your environment.

### Connection string

Encryption is mandatory. The `-c` option must include a certificate policy:

- `host/<sha256_fingerprint>[:port]`
- `host/nocertcheck[:port]`
- `host[:port]` (will use saved fingerprint if present)
- `host[:port]/nocertcheck`
- `host1,host2,host3[:port]` (tries hosts in random order until one connects)

If `:port` is omitted, `8563` is used.

Example:

```
-c localhost/9aefaa1987a5a191d6e23c714a480b461c5e3462e0a98ffb6683edb10fa99400:8563
```

On first connect, the client saves the server certificate fingerprint to
`~/.exaplus_known_hosts` (override with `EXAPLUS_KNOWN_HOSTS`). If the
certificate changes, the client errors and instructs you to run once with
`/nocertcheck` to update, or remove the entry manually.

History is saved to `~/.exaplus_history` (override with `EXAPLUS_HISTORY`).

## Supported CLI options

- `-c <connection>`
- `-u <user>`
- `-p <password>` (or prompt if omitted)
- `-s <schema>`
- `-sql <statement>`
- `-f <file>` (semicolon splitter; CREATE SCRIPT/UDF uses `/;` or `/` line terminator)
- `-B <file>` (execute as a single statement)
- `-init <file>`
- `-autocommit {ON|OFF}`
- `-F <kB>` (fetch size, default 1000)
- `-Q <seconds>` (query timeout, default -1)
- `-q` (quiet)
- `-x` (exit on error)

## Notes

- Password encryption uses a pure-Lua PKCS#1 v1.5 RSA implementation.
- WebSocket transport uses embedded LuaSocket/LuaSec modules copied under `vendor/`.
- JSON messages are uncompressed.
- Interactive mode includes in-memory history with Up/Down and Ctrl+R reverse search.
- CREATE SCRIPT / UDF statements ignore semicolons inside the body until a line with only `/;` (or `/`) is seen.

## Tests

Tests require access to an Exasol instance:

```
./tests/run_all.sh
```

## Limitations

- Not a full replacement for the full `exaplus` CLI; only the options listed above are supported.
- Requires Exasol WebSocket API v5.
- JSON messages are uncompressed.
- Bundled native modules are Linux x86_64 only.

## License

MIT. See [LICENSE](LICENSE).

## Trademark

Exasol is a trademark of Exasol AG. This project is not affiliated with or endorsed by Exasol.

## Shortcuts

- `Ctrl+A` / `Ctrl+E`: start/end of line
- `Left` / `Right`: move by character
- `Ctrl+Left` / `Ctrl+Right`: move by word
- `Ctrl+W`: delete previous word
- `Up` / `Down`: history navigation
- `Ctrl+R`: reverse history search
- `Ctrl+D`: exit if line is empty
