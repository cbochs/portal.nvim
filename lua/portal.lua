local Portal = {}

---@class Portal.PortalOptions
---@field iter Portal.Iterator
---@field query? Portal.Predicate[]

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

---@param opts Portal.PortalOptions
function Portal.tunnel(opts)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    local results = Search.search(opts.iter, opts.query)
    local windows = Search.open(results, Settings.labels, Settings.window_options)
    Search.select(windows, Settings.escape)
end

return Portal
