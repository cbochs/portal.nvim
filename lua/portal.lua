local Portal = {}

local initialized = false

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

---@generic T
---@param list T[]
---@param opts Portal.SearchOptions
function Portal.tunnel(list, opts)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    local results = Search.search(list, opts)
    local windows = Search.open(results, Settings.labels, Settings.window_options)
    Search.select(windows, Settings.escape)
end

return Portal
