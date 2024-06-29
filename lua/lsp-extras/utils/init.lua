local M = {}

---A wrapper for backward compability
---@param filters vim.lsp.get_clients.Filter
M.get_clients = function(filters)
  ---@diagnostic disable-next-line: deprecated
  local getter = vim.lsp.get_clients or vim.lsp.get_active_clients
  return getter(filters)
end

return M
