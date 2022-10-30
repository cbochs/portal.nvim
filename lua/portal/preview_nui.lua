local nui_popup = require("nui.popup")

local M = {}

local popups = {}

--- @param jumps Portal.Jump[]
--- @param decorator Portal.Decorator
--- @param labeller Portal.Labeller
function M.preview_jumps(jumps, decorator, labeller)
    M.clear()

    for index, jump in pairs(jumps) do
        local decorations = decorator(index, jump, labeller)
        local popup = nui_popup(decorations.nui_popup())
        table.insert(popups, popup)
    end

end

function M.clear()
    for _, popup in pairs(popups) do
        popup:unmount()
    end
end

return M
