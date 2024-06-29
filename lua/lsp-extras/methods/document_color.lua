local M = {}

local utils = require("lsp-extras.utils")
local logger = require("lsp-extras.utils.logger")

local methods = vim.lsp.protocol.Methods
local augroup = vim.api.nvim_create_augroup("vim_lsp_documentcolor", {})
local namespace = vim.api.nvim_create_namespace("vim_lsp_documentcolor")

---@type uv_timer_t | nil
local request_timer = nil
local default_debounce = 200
local enabled_buffers = {}
local is_enabled = false

---@alias LspExtras.ColorStyle "inline" | "background" | "foreground"

---@class LspExtras.ColorOptions
---@field style LspExtras.ColorStyle
---@field symbol? string
---@field debounce? number

---Convertion from 0-1 range to 0-255
---@param lsp_color number
local function normalize_color(lsp_color) return math.floor(lsp_color * 255) end

---@param color lsp.Color
---@param style LspExtras.ColorStyle
local function create_highlight(color, style)
  local red = normalize_color(color.red)
  local green = normalize_color(color.green)
  local blue = normalize_color(color.blue)
  local hex_color = string.format("%02x%02x%02x", red, green, blue)
  local suffix = style == "background" and "Bg" or "Fg"
  local group = "LspExtras" .. suffix .. hex_color
  local hl_opts

  if style == "background" then
    -- Choose the text color depending on the color brightness
    -- https://stackoverflow.com/questions/3942878
    local luminance = red * 0.299 + green * 0.587 + blue * 0.114
    local fg = luminance > 186 and "#000000" or "#FFFFFF"
    hl_opts = { fg = fg, bg = "#" .. hex_color }
  else
    hl_opts = { fg = "#" .. hex_color }
  end

  if vim.fn.hlID(group) < 1 then vim.api.nvim_set_hl(0, group, hl_opts) end

  return group
end

---@param bufnr number
---@param info lsp.ColorInformation
---@param opts LspExtras.ColorOptions
local function set_extmark(bufnr, info, opts)
  local hl_group = create_highlight(info.color, opts.style)
  local start_row = info.range.start.line
  local start_col = info.range.start.character
  local ext_opts = {}

  if opts.style == "inline" then
    ext_opts.virt_text = { { opts.symbol, hl_group } }
    ext_opts.virt_text_pos = "inline"
  else
    ext_opts.hl_group = hl_group
    ext_opts.end_row = info.range["end"].line
    ext_opts.end_col = info.range["end"].character
    ext_opts.priority = 1000
  end

  vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, ext_opts)
  table.insert(enabled_buffers, bufnr)
end

---@param client vim.lsp.Client
---@param opts LspExtras.ColorOptions
local function color_request(client, opts)
  local bufnr = vim.api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }

  client.request(
    methods.textDocument_documentColor,
    params,
    ---@param error lsp.ResponseError
    ---@param result lsp.ColorInformation[]
    function(error, result)
      if error and error.code == -32601 then return end -- Skip unhandeled method exceptions
      if error then return logger.error(error.message) end
      if not result or not vim.api.nvim_buf_is_valid(bufnr) then return end

      vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)

      for _, value in pairs(result) do
        pcall(function() set_extmark(bufnr, value, opts) end) -- Dismiss extmarks errors
      end
    end,
    bufnr
  )
end

---@param opts LspExtras.ColorOptions
local function request_clients(opts)
  if request_timer and not request_timer:is_closing() then
    request_timer:stop()
    request_timer:close()
  end

  request_timer = vim.defer_fn(function()
    local clients = utils.get_clients({ method = methods.textDocument_documentColor })

    for _, client in pairs(clients) do
      color_request(client, opts)
    end
  end, opts.debounce or default_debounce)
end

M.is_enabled = function() return is_enabled end

---Enables color hints for all buffers.
---Extmarks are updated on `BufEnter`, `TextChanged` and `TextChangedI`.
---@param opts LspExtras.ColorOptions
M.enable = function(opts)
  vim.validate({ opts = { opts, "table" } })
  vim.validate({ style = { opts.style, "string" } })

  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    group = augroup,
    callback = function() request_clients(opts) end,
  })

  request_clients(opts)
  is_enabled = true
end

---Disables color hints for all buffers.
M.disable = function()
  for _, bufnr in pairs(enabled_buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    end
  end

  vim.api.nvim_clear_autocmds({ group = augroup })
  is_enabled = false
end

return M
