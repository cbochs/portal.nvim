local M = {}

--- @alias Grapple.Label integer

--- @alias Grapple.Labeller fun(index: integer, jump: Grapple.Jump): string

--- @param index integer
--- @param jump Grapple.Jump
--- @return Grapple.Label
function M.default(index, jump)
    local config = require("grapple.config")
    local DEFAULT_LABELS = { "j", "k", "h", "l" }

    return config.decorate.labels[index] or DEFAULT_LABELS[index]
end

return M
