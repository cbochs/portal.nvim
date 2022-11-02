local types = require("portal.types")

local M = {}

--- @type Portal.Namespace
M.namespace = vim.api.nvim_create_namespace("PortalNamespace")

M.groups = {
	border = "PortalBorder",
	border_backward = "PortalBorderBackward",
	border_forward = "PortalBorderForward",
	border_none = "PortalBorderNone",
	label = "PortalLabel",

	leap_tag_active = "PortalLeapTagActive",
	leap_tag_inactive = "PortalLeapTagInactive",
}

--- @param border string | table
--- @param direction Portal.Direction
--- @return table
function M.border(border, direction)
	local BORDER_CHARS = {
		none = { "", "", "", "", "", "", "", "" },
		single = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
	}

	border = border or "none"
	if type(border) == "string" then
		border = BORDER_CHARS[border]
	end

	local highlight_group = nil
	if direction == types.Direction.BACKWARD then
		highlight_group = M.groups.border_backward
	elseif direction == types.Direction.FORWARD then
		highlight_group = M.groups.border_forward
	elseif direction == types.Direction.NONE then
		highlight_group = M.groups.border_none
	end

	local border_chars = {}
	for i, char in pairs(border) do
		border_chars[i] = { char, highlight_group }
	end

	return border_chars
end

function M.load()
	--- The default theme is based off of catppuccin
	local default_theme = {
		PortalBorder = { fg = "#fab387" },
		PortalBorderBackward = { link = M.groups.border },
		PortalBorderForward = { link = M.groups.border },
		PortalBorderNone = { fg = "#89b4fa" },
		PortalLabel = { bg = "#a6e3a1", fg = "#1e1e2e" },

		PortalLeapTagActive = { fg = "#a6e3a1" },
		PortalLeapTagInactive = { fg = "#313244" },
	}

	for _, group in pairs(M.groups) do
		vim.api.nvim_set_hl(0, group, default_theme[group] or {})
	end
end

return M
