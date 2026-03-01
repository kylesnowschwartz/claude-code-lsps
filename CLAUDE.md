# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a collection of LSP (Language Server Protocol) plugins for Claude Code. Each plugin enables language intelligence features (go-to-definition, find-references, hover, diagnostics) for a specific programming language.

This is a fork of [kylesnowschwartz/claude-code-lsps](https://github.com/kylesnowschwartz/claude-code-lsps) (upstream), maintained independently for a specific macOS dev environment. The upstream tracks the community collection (24+ languages); this fork carries plugins and configuration tuned to Go, Ruby, Python, TypeScript, Lua, Rust, and Bash.

## Installation

### Prerequisites
- Claude Code 2.0.74+
- `ENABLE_LSP_TOOL` must be `"1"` in `~/.claude/settings.json` (the feature is not on by default)

### Quick Install
Run `./install.sh` to: enable the LSP feature flag, register this marketplace, install the 7 target plugins, and check that each LSP binary is on PATH.

### Target Plugins

| Plugin | Binary | Typical install |
|--------|--------|-----------------|
| pyright | `pyright-langserver` | `pip install pyright` |
| gopls | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| typescript-language-server | `typescript-language-server` | `npm i -g typescript-language-server typescript` |
| lua-language-server | `lua-language-server` | `brew install lua-language-server` |
| bash-language-server | `bash-language-server` | `brew install bash-language-server` |
| rust-analyzer | `rust-analyzer` | `rustup component add rust-analyzer` |
| ruby-lsp | `ruby-lsp` | `gem install ruby-lsp` |

Each plugin's `hooks/check-*.sh` attempts auto-install on session start if the binary is missing.

### Verifying

1. Start a new Claude Code session (LSP servers only initialize on startup)
2. Check debug log: `cat ~/.claude/debug/latest | grep "Total LSP servers loaded"`
3. In-session: press `Ctrl+O` for diagnostics overlay
4. Run `claude plugin list` to confirm plugins are enabled (they sometimes land disabled after install)

## Known Issues

- **rootUri not passed** ([anthropics/claude-code#27220](https://github.com/anthropics/claude-code/issues/27220)): Claude Code doesn't pass workspace root to LSP servers during initialization. Servers that rely on project-root config discovery (e.g., lua-language-server reading `.luarc.json`) fall back to single-file mode. Workaround: pass `--configpath` via args in `.lsp.json`.
- **Plugins disabled after install**: Plugins sometimes land in a disabled state. Check with `claude plugin list` and enable manually.

## Repository Structure

Each plugin is a self-contained directory with this structure:

```
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json      # Plugin metadata
├── .lsp.json            # LSP server configuration (auto-discovered)
└── hooks/
    ├── hooks.json       # Hook definitions (auto-discovered, runs on SessionStart)
    └── check-<name>.sh  # Auto-install script for the LSP binary
```

## Key Files

### `.lsp.json`
Configures the language server. Required fields:
- `command`: The LSP binary to execute
- `extensionToLanguage`: Maps file extensions to language IDs

Optional fields:
- `args`: CLI arguments passed to the command
- `settings`: Server settings delivered via `workspace/didChangeConfiguration` (PUSH). Namespace varies per server (e.g., `gopls: {...}`, `python: { analysis: {...} }`, `Lua: {...}`, `bashIde: {...}`)
- `initializationOptions`: Sent in the LSP `initialize` request. Used by servers that read config at startup rather than via `didChangeConfiguration` (e.g., typescript-language-server, ruby-lsp, rust-analyzer)
- `loggingConfig`: Debug logging support (see Debug Logging section)

Note: Claude Code disables `workspace/configuration` PULL. Use `settings` (PUSH via `didChangeConfiguration`) or `initializationOptions` depending on what the server expects. Lifecycle fields (`restartOnCrash`, `startupTimeout`, etc.) are not yet supported and will cause initialization failure if present.

### `hooks/check-*.sh`
Auto-install scripts that run on session start. Pattern:
1. Check if LSP binary exists → exit silently if yes
2. Check if language runtime exists → show install instructions if no
3. Attempt auto-install → show PATH instructions if needed

## Adding a New Plugin

1. Create a new directory with the plugin name
2. Add `.claude-plugin/plugin.json` with name, description, version, and author
3. Add `.lsp.json` with command and extensionToLanguage mapping
4. Add `hooks/hooks.json` to run auto-install on SessionStart
5. Add `hooks/check-<name>.sh` auto-install script
6. Update README.md: add to Available Plugins table and Manual Installation section

Note: `.lsp.json` and `hooks/hooks.json` are auto-discovered from default locations - no need to reference them in `plugin.json`.

## Debug Logging

Plugins that support args/env-based logging should include `loggingConfig`:
- Args-based: `"loggingConfig": { "args": ["--verbose"] }`
- Env-based: `"loggingConfig": { "env": { "DEBUG": "true" } }`

Use `${CLAUDE_PLUGIN_LSP_LOG_FILE}` for log file paths.

## LSP Operations

Claude Code maps natural language to these LSP operations:
- `goToDefinition` — "Where is X defined?"
- `findReferences` — "Find all usages of X"
- `hover` — "What type is X?"
- `documentSymbol` — "List all functions in this file"
- `workspaceSymbol` — "Find the ClassName"
- `goToImplementation` — "What implements Interface?"
- `incomingCalls` / `outgoingCalls` — "What calls X?" / "What does X call?"

## References

- [Official LSP docs](https://code.claude.com/docs/en/plugins-reference#lsp-servers)
- [LSP setup blog post](https://karanbansal.in/blog/claude-code-lsp/) — walkthrough with debugging tips
- Requires Claude Code 2.0.74+
