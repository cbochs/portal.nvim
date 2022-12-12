local types = require("portal.types")

local M = {}

---@enum Portal.HighlightGroup
M.groups = {
    border = "PortalBorder",
    border_backward = "PortalBorderBackward",
    border_forward = "PortalBorderForward",
    border_none = "PortalBorderNone",
    label = "PortalLabel",
}

M.default = {
    [M.groups.border] = { link = "FloatBorder" },
    [M.groups.border_backward] = { link = M.groups.border },
    [M.groups.border_forward] = { link = M.groups.border },
    [M.groups.border_none] = { link = M.groups.border },
    [M.groups.label] = { bg = "#a6e3a1", fg = "#1e1e2e" },
}

---@param window integer
---@param direction Portal.Direction
---@return Portal.HighlightGroup
function M.set_border(window, direction)
    local highlight_group
    if direction == types.direction.backward then
        highlight_group = M.groups.border_backward
    elseif direction == types.direction.forward then
        highlight_group = M.groups.border_forward
    elseif direction == types.direction.none then
        highlight_group = M.groups.border_none
    else
        error("Invalid jump direction")
    end
    vim.api.nvim_win_set_option(window, "winhl", "FloatBorder:" .. highlight_group .. ",Title:" .. highlight_group)
end

function M.load()
    for _, group in pairs(M.groups) do
        vim.api.nvim_set_hl(0, group, M.default[group] or {})
    end
end

return M
