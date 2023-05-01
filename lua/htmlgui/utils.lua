local a = vim.api
local ts = vim.treesitter
local clock = os.clock
local parsers = require("nvim-treesitter.parsers")

local M = {}

function M.sleep(n)
	local t0 = clock()
	while clock() - t0 <= n do
	end
end

function M.shallow_copy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function M.validate_config(config, default_config)
	-- create shallow copy of config, extend with defaults
	if config == nil then
		config = default_config
	end
	vim.validate({ config = { config, "table" } })
	config = vim.tbl_extend("keep", config, default_config)
	return M.shallow_copy(config)
end

function M.load_script(scriptpath)
	-- load script file as lua module
	scriptpath = string.sub(scriptpath, 1, string.len(scriptpath) - 4)
	if pcall(function()
		require(scriptpath)
	end) then
		local script = require(scriptpath)
		return script
	end
end

function M.clean_up_text(text, remove_parens)
	if remove_parens then
		text = vim.trim(string.gsub(text, "{", ""))
		text = vim.trim(string.gsub(text, "}", ""))
	end
	local lines = vim.split(text, "\n")
	local clean = {}
	for _, line in pairs(lines) do
		table.insert(clean, vim.trim(line))
	end
	return table.concat(clean, " ")
end

function M.focus(win_name, state)
	if state[win_name] ~= nil then
		if state[win_name].win ~= nil then
			a.nvim_set_current_win(state[win_name].win)
		else
			vim.notify("Unknown name :" .. win_name, vim.log.levels.ERROR)
		end
	end
end

function M.get_width_height(win)
	local width = a.nvim_win_get_width(win)
	local height = a.nvim_win_get_height(win)
	return { width = width, height = height }
end

function M.get_root(buf, lang)
	if lang == nil then
		lang = "html"
	end
	local parser = parsers.get_parser(buf, lang)
	return parser:parse()[1]:root()
end

function M.get_text_from_range(range, buf)
	-- simple trim and concat
	local lines = a.nvim_buf_get_text(buf, range[1], range[2], range[3], range[4], {})
	local text = ""
	if vim.tbl_count(lines) > 1 then
		vim.tbl_map(function(line)
			text = text .. vim.trim(line)
		end, lines)
	else
		text = lines[1]
	end
	return text
end

function M.get_matches(query, root, buf, lang)
	local parsed_query = ts.query.parse(lang, query)
	local s, _, e, _ = root:range()
	local matches = {}
	for _, node, metadata in parsed_query:iter_captures(root, buf, s, e) do
		local ids = vim.tbl_keys(metadata)
		if vim.tbl_count(ids) > 0 then
			metadata = metadata[ids[1]]
		end
		table.insert(matches, { node = node, metadata = metadata })
	end
	return matches
end

function M.get_text_from_first_tag(query, root, buf, lang)
	local tt = M.get_matches(query, root, buf, lang)
	if vim.tbl_count(tt) > 0 then
		return M.get_text_from_range(tt[1].metadata.range, buf)
	end
end

return M
