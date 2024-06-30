local M = {}

local utils = require("lsp-extras.utils")
local logger = require("lsp-extras.utils.logger")

local methods = vim.lsp.protocol.Methods
local namespace = vim.api.nvim_create_namespace("vim_lsp_ontypeformatting")

local is_enabled = false

---@class LspExtras.OnTypeFormattingOptions
---@field enabled_servers? string[] Only send requests to the specified servers
---@field trim_final_newline? boolean Trim trailing whitespace on a line
---@field trim_trailing_whitespace? boolean Insert a newline character at the end of the file if one does not exist
---@field insert_final_newline? boolean Trim all newlines after the final newline at the end of the file

---@param client vim.lsp.Client
---@param key string
---@param bufnr number
---@param opts LspExtras.OnTypeFormattingOptions
local function format_request(client, key, bufnr, opts)
  local bo = vim.bo[bufnr]
  local cursor = vim.api.nvim_win_get_cursor(0)

  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = { line = cursor[1] - 1, character = cursor[2] },
    ch = key,
    options = {
      tabSize = bo.shiftwidth,
      insertSpaces = not bo.expandtab,
      trimTrailingWhitespace = opts.trim_trailing_whitespace,
      trimFinalNewlines = opts.trim_final_newline,
      insertFinalNewline = opts.insert_final_newline,
    },
  }

  client.request(
    methods.textDocument_onTypeFormatting,
    params,
    ---@param error lsp.ResponseError
    ---@param result lsp.TextEdit[]
    function(error, result)
      if error then return logger.error(error.message) end
      if not result or not vim.api.nvim_buf_is_valid(bufnr) then return end

      vim.lsp.util.apply_text_edits(result, bufnr, client.offset_encoding)
    end,
    bufnr
  )
end

---@param client vim.lsp.Client
local function get_trigger_chars(client)
  local server_cap = client.server_capabilities or {}
  local options = server_cap.documentOnTypeFormattingProvider or {}

  return vim.tbl_extend(
    "error",
    { options.firstTriggerCharacter },
    options.moreTriggerCharacter or {}
  )
end

---@param key string
---@param opts LspExtras.OnTypeFormattingOptions
local function request_clients(key, opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = utils.get_clients({ method = methods.textDocument_onTypeFormatting })
  local servers = opts.enabled_servers

  for _, client in pairs(clients) do
    local is_valid = not servers or vim.tbl_contains(servers, client.name)
    local is_attached = client.attached_buffers[bufnr]

    if is_valid and is_attached then
      local trigger_chars = get_trigger_chars(client)
      if vim.tbl_contains(trigger_chars, key) then
        return format_request(client, key, bufnr, opts)
      end
    end
  end
end

M.is_enabled = function() return is_enabled end

---Enabes on type formatting in all buffers attached to capable servers
---
---The implementation uses `vim.on_key` to listen to key presses
---@param opts? LspExtras.OnTypeFormattingOptions
M.enable = function(opts)
  opts = opts or {}

  vim.on_key(
    -- The function should be called after the key insertion
    vim.schedule_wrap(function(key)
      if key == "\r" then key = "\n" end -- newline is interpreted as \r
      if vim.fn.mode() == "i" then request_clients(key, opts) end
    end),
    namespace
  )

  is_enabled = true
end

---Disables on type formatting in all buffers
M.disable = function()
  vim.on_key(nil, namespace) -- Removes the callback

  is_enabled = false
end

return M
