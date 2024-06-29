local M = {}

local function notify_fn(level)
  return
  ---@param message string
  function(message) vim.notify("[lsp-extras] " .. message, level) end
end

M.debug = notify_fn(vim.log.levels.DEBUG)
M.info = notify_fn(vim.log.levels.INFO)
M.warn = notify_fn(vim.log.levels.WARN)
M.error = notify_fn(vim.log.levels.ERROR)

return M
