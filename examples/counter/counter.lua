local M = {}

local a = vim.api
M.state = { count = 1 }

function M.handle_j(self, data)
  self.state.count = self.state.count + 1
  local text = string.format("%s %d", data.element.text, self.state.count)
  a.nvim_buf_set_lines(data.buf, 0, -1, false, { text })
end

return M
