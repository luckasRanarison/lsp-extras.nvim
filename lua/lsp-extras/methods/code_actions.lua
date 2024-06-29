local M = {}

local methods = vim.lsp.protocol.Methods
local augroup = vim.api.nvim_create_augroup("vim_lsp_codeactions", {})
local namespace = vim.api.nvim_create_namespace("vim_lsp_codeactions")

local is_enabled = false

---@class LspExtras.CodeAction
---@field title string
---@field kind? lsp.CodeActionKind
---@field diagnostics? lsp.Diagnostic[]
---@field isPreferred? boolean
---@field disabled? lsp._anonym4.disabled
---@field edit? lsp.WorkspaceEdit
---@field command? lsp.Command
---@field data? lsp.LSPAny
---@field client? vim.lsp.Client

---@param results vim.lsp.CodeActionResultEntry[]
---@param line number
---@param bufnr number
---@param opts LspExtras.CodeActionOptions
local function set_extmarks(results, line, bufnr, opts)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if bufnr ~= vim.api.nvim_get_current_buf() then return end
  if line ~= vim.api.nvim_win_get_cursor(0)[1] - 1 then return end

  ---@type LspExtras.CodeAction[]
  local actions = {}

  for client_id, value in pairs(results) do
    local client = vim.lsp.get_client_by_id(client_id)
    for _, action in pairs(value.result or {}) do
      actions[#actions + 1] = vim.tbl_extend("error", action, { client = client })
    end
  end

  if vim.tbl_isempty(actions) then return end

  vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    hl_mode = "combine",
    virt_text = { { opts.format and opts.format(actions) or actions[1].title, "Comment" } },
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

---@param opts LspExtras.CodeActionOptions
local function code_action_request(opts)
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)

  local bufnr = vim.api.nvim_get_current_buf()
  local params = vim.lsp.util.make_range_params()

  params.context = {
    triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic,
    diagnostics = get_line_diagnostics(),
  }

  vim.lsp.buf_request_all(
    bufnr,
    methods.textDocument_codeAction,
    params,
    function(results) set_extmarks(results, params.range.start.line, bufnr, opts) end
  )
end

---@class LspExtras.CodeActionOptions
---@field update_on_insert? boolean If `true` extmarks will also get updated in insert mode
---@field format? fun(actions: LspExtras.CodeAction[]): string The function used for formatting the hint text

---Enables code action hints for all buffers.
---
---Hints are displayed as extmarks appended at the end of the line.
---Extmarks are updated on `CursorMoved` and `TextChanged` by default.
---@param opts? LspExtras.CodeActionOptions
M.enable_hints = function(opts)
  if is_enabled then return end

  local events = { "CursorMoved", "TextChanged" }
  local local_opts = opts or {}

  if local_opts.update_on_insert then
    vim.list_extend(events, { "CursorMovedI", "TextChangedI" })
  else
    vim.api.nvim_create_autocmd("InsertEnter", {
      group = augroup,
      callback = function() vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1) end,
    })
  end

  vim.api.nvim_create_autocmd(events, {
    group = augroup,
    callback = function() code_action_request(local_opts) end,
  })

  code_action_request(local_opts)
  is_enabled = true
end

M.disable_hints = function()
  vim.api.nvim_clear_autocmds({ group = augroup })
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
  is_enabled = false
end

return M
