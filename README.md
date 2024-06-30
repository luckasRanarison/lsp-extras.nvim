# lsp-extras.nvim

> [!NOTE]
> This is a work in progress and the modules are still experimental

This plugin aims to provide support for LSP methods not yet available in Neovim, along with some non-standard LSP utilities (extras).

The plugin doesn't have any configuration options; it only provides APIs that you can map. To use it, simply use your favorite package manager and import the modules you are interested in.

All the functions are strongly typed and documented, so most of them should be self-explanatory if you are using [lua-language-server](https://github.com/LuaLS/lua-language-server).

## Modules

- [lsp_extras.document_color](#lsp_extrasdocument_color-textdocumentdocumentcolor)
- [lsp_extras.on_type_formatting](#lsp_extrason_type_formatting-textdocumentontypeformatting)
- [lsp_extras.code_action](#lsp_extrascode_action-textdocumentcodeaction)

### lsp_extras.document_color ([textDocument/documentColor](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentColor))

Provides the ability to display color hints in all buffers with the specified style.

```lua
local color = require("lsp-extras").document_color

---@class LspExtras.ColorOptions
---@field style "inline" | "background" | "foreground" The color hints style
---@field symbol? string The symbol to display if the style is `inline`
---@field request_delay? number Request delay in milliseconds, the default value is 200ms

color.enable({ style = "inline", symbol = "󰝤 " }) -- Enables color hints in all buffers
color.disable() -- Disables color hints
color.is_enabled() -- Can be used for toggling
```

> [!NOTE]
> Extmarks are updated on `BufEnter`, `TextChanged` and `TextChangedI`

### lsp_extras.onTypeFormatting ([textDocument/onTypeFormatting](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_onTypeFormatting))

Provides the ability to format the buffer when trigger characters are typed.

```lua
local type_formatting = require("lsp_extras").on_type_formatting

---@class LspExtras.OnTypeFormattingOptions
---@field enabled_servers? string[] Only send requests to the specified servers
---@field trim_final_newline? boolean Trim trailing whitespace on a line
---@field trim_trailing_whitespace? boolean Insert a newline character at the end of the file if one does not exist
---@field insert_final_newline? boolean Trim all newlines after the final newline at the end of the file

type_formatting.enable({ enabled_servers = { "lua_ls" } }) -- Enabes on type formatting in all buffers attached to capable servers
type_formatting.disable() -- Disables on type formatting
type_formatting.is_enabled() -- Can be used for toggling
```

> [!NOTE]
> The implementation uses `vim.on_key` to listen to key presses

### lsp_extras.code_action ([textDocument/codeAction](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeAction))

Provides the ability to display custom code action hints for the current line in all buffers as inline text.

```lua
local code_action = require("lsp-extras").code_action

---@class LspExtras.CodeActionHintsOptions
---@field update_on_insert? boolean If `true` extmarks will also get updated in insert mode
---@field format? fun(actions: LspExtras.CodeAction[]): string The function used for formatting the hint text

code_action.disable() -- Disables code action hints
code_action.enable() -- Enables code action hints for the current line in all buffers
code_action.is_enabled() -- Can be used for toggling
```

> [!NOTE]
> Extmarks are updated on `CursorMoved`, `TextChanged` and on their insert mode variants if `update_on_insert` is set to `true`

An example of custom format function:

```lua
---@param actions LspExtras.codeAction[]
local format = function(actions)
  local first = actions[1]
  local kind = vim.split(first.kind, "%.")[1]
  local icons = { quickfix = "🔧", refactor = "💡", source = "🔗" }
  return (icons[kind] or "") .. " " .. first.title
end
```

## TODOs

- [workspace/willRenameFiles](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_willRenameFiles)
- [textDocument/documentLink](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_documentLink)

## Contributing

Pull requests, issues reports and features ideas are all welcome.
