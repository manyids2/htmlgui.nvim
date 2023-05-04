local M = {}

M.state = { count = 1 }

function M.increment(self, data)
  self.state.count = self.state.count + 1
  local text = string.format("%s %d", data.text, self.state.count)
  return { lines = { text } }
end

function M.decrement(self, data)
  self.state.count = self.state.count - 1
  local text = string.format("%s %d", data.text, self.state.count)
  return { lines = { text } }
end

return M
