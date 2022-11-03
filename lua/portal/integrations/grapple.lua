local deprecated = require("portal.deprecated")

local M = {}

---@param jump Portal.Jump
---@return boolean
local function is_tagged(jump)
    local query = require("portal.query")
    local grapple = require("grapple")
    return query.valid.predicate(jump) and query.different.predicate(jump) and grapple.exists({ buffer = jump.buffer })
end

function M.register()
    local ok, _ = pcall(require, "grapple")
    if not ok then
        require("portal.log").warn("Unable to register query item for grapple.nvim. Please ensure plugin is installed.")
        return
    end

    local query = require("portal.query")
    query.register("grapple", is_tagged, { name = "Tagged", name_short = "T" })
    query.register("tagged", function(jump)
        deprecated(
            'The "tagged" query item has been deprecated and will be removed. Please use the "grapple" query item instead.'
        )
        return is_tagged(jump)
    end, { name = "Tagged", name_short = "T" })
end

return M
