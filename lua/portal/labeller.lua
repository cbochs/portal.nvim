local M = {}

--- @alias Portal.Label integer

--- @alias Portal.Labeller fun(index: integer, jump: Portal.Jump): string

--- @param index integer
--- @param jump Portal.Jump
--- @return Portal.Label
function M.default(index, jump)
    local config = require("portal.config")
    return config.default.labels[index]
end

return M
