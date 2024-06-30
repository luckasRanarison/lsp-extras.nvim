local M = {}

local DEFAULT_DELAY = 200

---A wrapper for backward compability
---@param filters? vim.lsp.get_clients.Filter
M.get_clients = function(filters)
  ---@diagnostic disable-next-line: deprecated
  local getter = vim.lsp.get_clients or vim.lsp.get_active_clients
  return getter(filters)
end

---@class LspExtras.TimerObject
---@field value uv_timer_t | nil

---@param timer LspExtras.TimerObject
---@param callback function
---@param delay? number
M.debounced_fn = function(timer, callback, delay)
  if timer.value and not timer.value:is_closing() then
    timer.value:stop()
    timer.value:close()
  end

  timer.value = vim.defer_fn(callback, delay or DEFAULT_DELAY)
end

return M
