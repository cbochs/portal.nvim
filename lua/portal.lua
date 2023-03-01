local Portal = {}

---@class Portal.PortalOptions
---@field list table
---@field start number
---@field direction Portal.Direction
---@field max_results number
---@field map Portal.MapFunction
---@field filter Portal.Predicate
---@field query? Portal.Predicate[]

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

---@param opts Portal.PortalOptions
function Portal.tunnel(opts)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    if not opts.list then
        error("Portal.tunnel: must provide a 'list' to search.")
    end

    local results = Search.search(opts.list, opts)
    local windows = Search.open(results, Settings.labels, Settings.window_options)
    Search.select(windows, Settings.escape)
end

---@param opts Portal.PortalOptions
function Portal.tunnel_forward(opts)
    Portal.tunnel(vim.tbl_extend("force", opts, { direction = "forward" }))
end

---@param opts Portal.PortalOptions
function Portal.tunnel_backward(opts)
    Portal.tunnel(vim.tbl_extend("force", opts, { direction = "backward" }))
end

return Portal
