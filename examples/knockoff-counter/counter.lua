local M = {}

local a = vim.api
M.state = { count = 1 }

function M.handle_j(self, data)
  self.state.count = self.state.count + 1
  local text = string.format("%s %d", data.text, self.state.count)
  return { lines = {text} }
end

return M
