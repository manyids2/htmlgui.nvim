local M = {}

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

return M
