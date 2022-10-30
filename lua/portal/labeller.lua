local M = {}

--- @alias Portal.Label integer

--- @alias Portal.Labeller fun(index: integer, jump: Grapple.Jump): string

--- @param index integer
--- @param jump Portal.Jump
--- @return Portal.Label
function M.default(index, jump)
    local config = require("portal.config")
    local DEFAULT_LABELS = { "j", "k", "h", "l" }

    return config.decorate.labels[index] or DEFAULT_LABELS[index]
end

return M
