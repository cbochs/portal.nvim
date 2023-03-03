local Portal = {}

local initialized = false

function Portal.initialize()
    if initialized then
        return
    end
    initialized = true

    require("portal.commands").create()
end

--- @param overrides? Portal.Settings
function Portal.setup(overrides)
    local Settings = require("portal.settings")

    Settings.update(overrides)
    require("portal.log").global({ log_level = Settings.log_level })

    Portal.initialize()
end

---@param queries Portal.Query[]
function Portal.tunnel(queries)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    -- Wrap a single query as a single item list
    -- Note: tables have length 0
    if #queries == 0 then
        queries = { queries }
    end

    local results = {}
    for _, query in ipairs(queries) do
        table.insert(results, Search.search(query))
    end

    if #queries > 1 then
        results = Iterator:new(results):flatten()
    else
        results = results[1]
    end

    local windows = Search.open(results, Settings.labels, Settings.window_options)
    Search.select(windows, Settings.escape)
end

return Portal
