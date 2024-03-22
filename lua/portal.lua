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
---@param overrides? Portal.Settings
function Portal.tunnel(queries, overrides)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    local settings = vim.tbl_deep_extend("force", Settings.as_table(), overrides or {})
    local results = Portal.search(queries)

    if settings.select_first and #results == 1 then
        results[1]:select()
        return
    end

    local windows = Portal.portals(results, settings)

    Portal.open(windows)

    local selected = Search.select(windows, settings.escape)
    if selected ~= nil then
        selected:select()
    end

    Portal.close(windows)
end

---@param queries Portal.Query[]
---@return Portal.Content[]
function Portal.search(queries)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    if not queries then
        error("Must provide at least one query to Portal search")
    end

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

    return results
end

---@param results Portal.Content[]
---@param overrides? Portal.Settings
---@return Portal.Window[]
function Portal.portals(results, overrides)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    local settings = vim.tbl_deep_extend("force", Settings.as_table(), overrides or {})
    local windows = Search.portals(results, settings.labels, settings.window_options)

    return windows
end

---@param windows Portal.Window[]
function Portal.open(windows)
    for _, window in ipairs(windows) do
        window:open()
        window:add_label()
    end

    -- Force UI to redraw to ensure windows appear before user input
    vim.cmd("redraw")
end

---@param windows Portal.Window[]
function Portal.close(windows)
    for _, window in ipairs(windows) do
        window:close()
    end

    -- Force UI to redraw to ensure windows appear before user input
    vim.cmd("redraw")
end

return Portal
