local Portal = {}

--- @param opts? Portal.Settings
function Portal.setup(opts)
    local Settings = require("portal.settings")
    Settings:update(opts)
end

---@class Portal.Options
---@field labels? string[]
---@field select_first? boolean
---@field win_opts? vim.api.keyset.win_config
---@field search? Portal.SearchOptions

---@param queries Portal.Query[]
---@param opts? Portal.Options
function Portal.tunnel(queries, opts)
    local Settings = require("portal.settings")

    opts = vim.tbl_deep_extend("keep", opts or {}, {
        labels = Settings.labels,
        select_first = Settings.select_first,
        win_opts = Settings.window_options,
        search = {
            filter = Settings.filter,
            limit = #Settings.labels,
            slots = Settings.slots,
        },
    })

    local results = Portal.search(queries, opts.search)
    if #results == 0 then
        vim.notify("Portal: empty search results")
    end

    if opts.select_first and #results == 1 then
        results[1]:select()
        return
    end

    local windows = Portal.portals(results, opts.labels, opts.win_opts)

    Portal.open(windows)

    local selected = Portal.select(windows)
    if selected ~= nil then
        selected:select()
    end

    Portal.close(windows)
end

---@param queries Portal.Query | Portal.Query[]
---@param opts? Portal.SearchOptions
---@return Portal.Content[]
function Portal.search(queries, opts)
    local Query = require("portal.query")
    local Iter = require("portal.iterator")

    -- A single query should just be searched with the provided options
    if getmetatable(queries) == Query then
        return queries:prepare(opts):search()
    end

    local query = Query.new(function()
        -- stylua: ignore
        return Iter.iter(queries)
            :map(Query.search)
            :flatten()
    end)

    return query:prepare(opts):search()
end

---@param results Portal.Content[]
---@param labels? string[]
---@param win_opts? vim.api.keyset.win_config
---@return Portal.Window[]
function Portal.portals(results, labels, win_opts)
    local Search = require("portal.search")
    local Settings = require("portal.settings")

    labels = labels or Settings.labels
    win_opts = win_opts or Settings.win_opts

    return Search.portals(results, labels, win_opts)
end

local function termcode_for(key)
    return vim.api.nvim_replace_termcodes(key, true, false, true)
end

---@param windows Portal.Window[]
---@return Portal.Window | nil
function Portal.select(windows)
    if vim.tbl_isempty(windows) then
        return
    end

    while true do
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok then
            return
        end

        for _, window in ipairs(windows) do
            if window.label == char then
                return window
            end
        end

        local quit_keys = { "q", termcode_for("<esc>"), termcode_for("<c-c>") }
        if vim.tbl_contains(quit_keys, char) then
            return
        end
    end
end

---@param windows Portal.Window[]
function Portal.open(windows)
    for _, window in ipairs(windows) do
        window:open()
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

---Manually force an extension to be registered. By default, extensions are
---lazily loaded, but eagerly loading and extension has the advantage of it
---appearing in the Portal autocomplete immediately.
---@param name string extension name
function Portal.register_extension(name)
    assert(require("portal.builtin")[name])
end

function Portal.initialize()
    -- Create highlights for Portal windows
    vim.cmd("highlight default link PortalLabel Search")
    vim.cmd("highlight default link PortalTitle FloatTitle")
    vim.cmd("highlight default link PortalBorder FloatBorder")
    vim.cmd("highlight default link PortalNormal NormalFloat")

    -- Create top-level user command
    vim.api.nvim_create_user_command(
        "Portal",

        ---@param opts any
        function(opts)
            local builtin = require("portal.builtin")[opts.fargs[1]]
            if not builtin then
                return vim.notify(("'%s' is not a valid Portal builtin"):format(builtin), vim.log.levels.ERROR)
            end

            local direction = opts.fargs[2]
            if not vim.tbl_contains({ "forward", "backward" }, direction) then
                return vim.notify(
                    ("'%s' is not a valid direction. Use either 'forward' or 'backward'"):format(direction),
                    vim.log.levels.ERROR
                )
            end

            local reverse = direction == "backward"
            builtin.tunnel({ search = { reverse = reverse } })
        end,
        {
            desc = "Portal",
            nargs = "*",
            complete = function(_, command, _)
                local Builtins = require("portal.builtin")

                local line_split = vim.split(command, "%s+")
                local n = #line_split - 2

                if n == 0 then
                    local builtins = vim.tbl_keys(Builtins)

                    return vim.tbl_filter(function(val)
                        return vim.startswith(val, line_split[2])
                    end, builtins)
                end

                if n == 1 then
                    local directions = { "forward", "backward" }

                    return vim.tbl_filter(function(val)
                        return vim.startswith(val, line_split[3])
                    end, directions)
                end
            end,
        }
    )
end

return Portal
