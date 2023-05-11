local a = vim.api
local M = {}

function M.preview_status()
	vim.notify("preview_status")
end

function M.preview_file()
	vim.notify("preview_file")
end

function M.do_commit()
	vim.ui.input({ prompt = "Commit message: " }, function(t)
		vim.notify("git commit -m " .. t)
	end)
end

function M.do_stage()
	local line = vim.trim(a.nvim_get_current_line())
	local parts = vim.split(line, " ")
	if vim.tbl_count(parts) == 2 then
		vim.notify("git add " .. parts[2])
	end
end

function M.do_unstage()
	local line = vim.trim(a.nvim_get_current_line())
	local parts = vim.split(line, " ")
	if vim.tbl_count(parts) == 3 then
		vim.notify("git reset -- " .. parts[3])
	end
end

function M.preview_branch()
	vim.notify("preview_branch")
end

function M.preview_commit()
	vim.notify("preview_commit")
end

function M.preview_stash()
	vim.notify("preview_stash")
end

return M
