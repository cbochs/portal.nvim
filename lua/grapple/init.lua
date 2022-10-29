local config = require("grapple.config")

local M = {}

--- @param opts Grapple.Config
function M.setup(opts)
    config.load(opts)
end

return M
