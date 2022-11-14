local types = require("portal.types")

local M = {}

---@type Portal.Namespace
M.namespace = vim.api.nvim_create_namespace("PortalNamespace")

---@enum Portal.HighlightGroup
M.groups = {
    border = "PortalBorder",
    border_backward = "PortalBorderBackward",
    border_forward = "PortalBorderForward",
    border_none = "PortalBorderNone",
    label = "PortalLabel",
}

---@param window integer
---@param direction Portal.Direction
---@return Portal.HighlightGroup
function M.set_border(window, direction)
    local highlight_group
    if direction == types.Direction.BACKWARD then
        highlight_group = M.groups.border_backward
    elseif direction == types.Direction.FORWARD then
        highlight_group = M.groups.border_forward
    elseif direction == types.Direction.NONE then
        highlight_group = M.groups.border_none
    else
        error("Invalid jump direction")
    end
    vim.api.nvim_win_set_option(window, "winhl", "FloatBorder:" .. highlight_group .. ",Title:" .. highlight_group)
end

function M.load()
    local default_theme = {
        [M.groups.border] = { link = "FloatBorder" },
        [M.groups.border_backward] = { link = M.groups.border },
        [M.groups.border_forward] = { link = M.groups.border },
        [M.groups.border_none] = { link = M.groups.border },
        [M.groups.label] = { bg = "#a6e3a1", fg = "#1e1e2e" },
    }

    for _, group in pairs(M.groups) do
        vim.api.nvim_set_hl(0, group, default_theme[group] or {})
    end
end

return M
