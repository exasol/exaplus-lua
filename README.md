# EXAplusLua (minimal)

A minimal Lua-based console client for Exasol WebSocket API v5. This is a simplified replacement for `Console/exaplus` with a reduced CLI.

## Usage

```
./exaplus -c localhost/<fingerprint>:8563 -u sys -p exasol
./exaplus -c localhost/nocertcheck:8563 -u sys -p exasol
./exaplus -c localhost:8563/nocertcheck -u sys -p exasol
./exaplus -c localhost/<fingerprint>:8563 -u sys -sql "SELECT 1;"
./exaplus -c n11,n12,n13/nocertcheck:8563 -u sys -p exasol
```

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

## Shortcuts

- `Ctrl+A` / `Ctrl+E`: start/end of line
- `Left` / `Right`: move by character
- `Ctrl+Left` / `Ctrl+Right`: move by word
- `Ctrl+W`: delete previous word
- `Up` / `Down`: history navigation
- `Ctrl+R`: reverse history search
- `Ctrl+D`: exit if line is empty
