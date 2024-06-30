local M = {}

local utils = require("lsp-extras.utils")
local logger = require("lsp-extras.utils.logger")

local methods = vim.lsp.protocol.Methods
local augroup = vim.api.nvim_create_augroup("vim_lsp_codeaction", {})
local namespace = vim.api.nvim_create_namespace("vim_lsp_codeaction")

---@type LspExtras.TimerObject
local request_timer = { value = nil }
local is_enabled = false

---@alias LspExtras.CodeAction (lsp.CodeAction | lsp.Command)

---@class LspExtras.CodeActionHintsOptions
---@field update_on_insert? boolean If `true` extmarks will also get updated in insert mode
---@field format? fun(actions: LspExtras.CodeAction[]): string The function used for formatting the hint text
---@field request_delay? number Request delay in milliseconds, the default value is 200ms

---@param results vim.lsp.CodeActionResultEntry[]
---@param line number
---@param bufnr number
---@param opts LspExtras.CodeActionHintsOptions
local function set_extmarks(results, line, bufnr, opts)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if bufnr ~= vim.api.nvim_get_current_buf() then return end
  if line ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then return end

  local actions = {}

  for _, value in pairs(results) do
    for _, action in pairs(value.result or {}) do
      actions[#actions + 1] = action
    end
  end

  if vim.tbl_isempty(actions) then return end

  vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    hl_mode = "combine",
    virt_text = { { opts.format and opts.format(actions) or actions[1].title, "LspInlayHint" } },
    virt_text_pos = "eol",
    priority = 200,
  })
end

local function get_line_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = row - 1 })
  local results = {}

  --- Convert vim diagnostics to LSP diagnostics
  for _, diagnostic in pairs(diagnostics) do
    local lsp_data = diagnostic.user_data.lsp

    if lsp_data then
      local value = vim.tbl_extend("force", diagnostic, lsp_data)
      value.range = {
        ["start"] = { character = value.col, line = value.lnum },
        ["end"] = { character = value.end_col, line = value.end_lnum },
      }
      results[#results + 1] = value
    end
  end

  return results
end

---@param opts LspExtras.CodeActionHintsOptions
local function code_action_request(opts)
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params()

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    diagnostics = get_line_diagnostics(),
  }

  utils.debounced_fn(request_timer, function()
    vim.lsp.buf_request_all(
      bufnr,
      methods.textDocument_codeAction,
      params,
      function(results) set_extmarks(results, params.range.start.line, bufnr, opts) end
    )
  end, opts.request_delay)
end

M.is_enabled = function() return is_enabled end

---Enables code action hints for the current line in all buffers.
---
---Hints are displayed as extmarks appended to the end of the line.
---Extmarks are updated on `CursorMoved` and `TextChanged` by default.
---@param opts? LspExtras.CodeActionHintsOptions
M.enable = function(opts)
  if is_enabled then return logger.warn("Code action hints are already enabled") end

  local update_events = { "CursorMoved", "TextChanged" }
  local clear_events = { "BufLeave" }

  opts = opts or {}

  if opts.update_on_insert then
    vim.list_extend(update_events, { "CursorMovedI", "TextChangedI" })
  else
    vim.list_extend(clear_events, { "InsertEnter" })
  end

  vim.api.nvim_create_autocmd(clear_events, {
    group = augroup,
    callback = function() vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1) end,
  })
  vim.api.nvim_create_autocmd(update_events, {
    group = augroup,
    callback = function() code_action_request(opts) end,
  })

  is_enabled = true

  code_action_request(opts)
end

---Disables code action hints in all buffers.
M.disable = function()
  vim.api.nvim_clear_autocmds({ group = augroup })
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

  is_enabled = false
end

return M
