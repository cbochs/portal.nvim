local config = require("portal.config")

local M = {}

--- @return string | nil
function M.get_label()
	local ok, char = pcall(vim.fn.getcharstr)
	if not ok then
		return nil
	end

	local escape_keys = config.keymaps.escape or {}
	for _, keycode in pairs(escape_keys) do
		if char == keycode then
			return nil
		end
	end

	return char
end

return M
