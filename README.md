# lsp-extras.nvim

> [!NOTE]
> This is a work in progress and the modules are still experimental

This plugins aims to provide support for LSP methods not yet available in Neovim and some non-standard LSP utilities (extras).

## Status

### Implemented

- [textDocument/documentColor](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentColor)

### Extras

- [textDocument/codeAction](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeAction)

### TODOs

- [workspace/willRenameFiles](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_willRenameFiles)
- [textDocument/onTypeFormatting](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_onTypeFormatting)
- [textDocument/documentLink](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentLink)

## APIs

### `textDocument/documentColor`

Provides the ability to display color hints for all buffers as inline text, as background or foreground color.

```lua
---@class LspExtras.ColorOptions
---@field style LspExtras.ColorStyle The color hints style
---@field symbol? string The symbol to display if the style is `inline`
---@field request_delay? number Request delay in milliseconds, the default value is 200ms

require("lsp-extras").document_color.enable(opts) -- Enables color hints for all buffers, extmarks are updated on `BufEnter`, `TextChanged` and `TextChangedI`
require("lsp-extras").document_color.disable() -- Disables color hitns for al buffers
require("lsp-extras").document_color.is_enabled()
```

### `textDocument/codeActions`

Provides the ability to display custom code action hints as inline text.

```lua
---@class LspExtras.CodeActionHintsOptions
---@field update_on_insert? boolean If `true` extmarks will also get updated in insert mode
---@field format? fun(actions: LspExtras.CodeAction[]): string The function used for formatting the hint text

require("lsp-extras").code_actions.enable(opts) -- Enables code action hints for all buffers extmarks are updated on `CursorMoved(I)` and `TextChanged(I)`
require("lsp-extras").code_actions.disable() -- Disables code action hints for all buffers
require("lsp-extras").code_actions.is_enabled()
```
