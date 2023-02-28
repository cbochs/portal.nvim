local Portal = {}

local initialized = false

---@class Portal.Options
---@field filter Portal.Predicate
---@field direction Portal.Direction
---@field start number
---@field max_results number
---@field transform Portal.MapFunction
---@field query? Portal.Predicate[]

function Portal.initialize()
    if initialized then
        return
    end
    initialized = true
end

-- luacheck: ignore
--- @param opts? Portal.Settings
function Portal.setup(opts)
    Portal.initialize()
end

---@param list table
---@param opts Portal.Options
---@return Portal.SearchResult
function Portal.search(list, opts)
    local Search = require("portal.search")

    local iter = Search.iter(list, opts)
    if not opts.query then
        return iter:collect()
    end

    return Search.query(iter, opts.query)
end

---@param list table
---@param opts Portal.Options
function Portal.jump(list, opts)
    -- luacheck: ignore
    local results = Portal.search(list, opts)
end

return Portal
