# Contributing

Thanks for your interest in contributing. This project aims to stay minimal and reliable.

## Ground Rules
- Be respectful and follow the Code of Conduct in `CODE_OF_CONDUCT.md`.
- Keep changes focused. Small, well-scoped PRs are easier to review.
- Avoid introducing new runtime dependencies without discussion.

## Development Setup
This repo is a single-file Lua client with local Lua modules under `lib/` and bundled LuaSocket/LuaSec modules under `vendor/`.

### Lua version
This project targets Lua 5.1.

### Quick Syntax Check
```bash
luac5.1 -p lib/*.lua tests/*.lua vendor/lua/5.1/*.lua vendor/lua/5.1/socket/*.lua vendor/lua/5.1/ssl/*.lua
lua5.1 -e "assert(loadfile('exaplus'))"
```

### Tests
The `tests/` scripts require access to an Exasol instance. If you have a local setup:
```bash
./tests/run_all.sh
```

## Pull Requests
1. Fork the repo and create a feature branch.
2. Make sure checks pass and new behavior is covered by tests where practical.
3. Keep commit messages clear and descriptive.
4. Open a PR describing the change, expected behavior, and any tradeoffs.

## License
By contributing, you agree that your contributions are licensed under the project license in `LICENSE`.

## Contributor License Policy
This project uses the inbound=outbound model. There is no CLA or DCO required.
