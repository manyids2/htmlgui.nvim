local a = vim.api
local utils = require("htmlgui.utils")
local style = require("htmlgui.ts_css").default_style

local M = {}

function M.get_selected_date()
  local buf = a.nvim_get_current_buf()
  local win = a.nvim_get_current_win()
  local pos = a.nvim_win_get_cursor(win)
  local text = a.nvim_buf_get_text(buf, pos[1] - 1, pos[2] - 1, pos[1] - 1, -1, {})
  local selected = vim.split(vim.trim(text[1]), " ")[1]
  return selected
end

function M.get_today_date()
  local selected = vim.trim(vim.fn.system("date +'%d'"))
  selected = tostring(tonumber(selected))
  return selected
end

function M.open_float(filepath)
  local opts = utils.get_win_opts(style, a.nvim_get_current_win())
  local buf = a.nvim_create_buf(true, false)
  local win = a.nvim_open_win(buf, true, opts)
  a.nvim_set_current_win(win)
  a.nvim_set_current_buf(buf)
  vim.cmd("e " .. filepath)
  vim.keymap.set("n", "q", function()
    a.nvim_win_close(win, false)
  end, { buffer = buf })
end

function M.get_filepath(selected, cwd)
  local month = vim.trim(vim.fn.system("date +'%b'"))
  local year = vim.trim(vim.fn.system("date +'%Y'"))
  local date = table.concat({ selected, month, year }, "-")
  local filepath = cwd .. "/" .. date .. ".md"
  return filepath
end

function M.edit(_, data)
  local cwd = data.attrs.cwd
  vim.fn.system("mkdir -p " .. cwd)
  local selected = M.get_selected_date()
  local filepath = M.get_filepath(selected, cwd)
  M.open_float(filepath)
  return {}
end

function M.today(_, data)
  local cwd = data.attrs.cwd
  vim.fn.system("mkdir -p " .. cwd)
  local selected = M.get_today_date()
  local filepath = M.get_filepath(selected, cwd)
  M.open_float(filepath)
  return {}
end

return M
