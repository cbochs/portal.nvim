local log = require("portal.log")

local Builtin = {}

---@alias Portal.QueryGenerator fun(o: Portal.SearchOptions, s: Portal.Settings): Portal.Query
---@alias Portal.Tunnel fun(o: Portal.SearchOptions)

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        local generator
        if pcall(require, ("portal.builtin.%s"):format(name)) then
            -- Portal provides this as a builtin
            generator = require(("portal.builtin.%s"):format(name))
        elseif pcall(require, ("portal.extension.%s"):format(name)) then
            -- Plugin provides this as an extension
            generator = require(("portal.extension.%s"):format(name))
        end

        if not generator then
            log.warn(("Unable to load builtin or extension %s"):format(name))
            return
        end

        local builtin = setmetatable({
            ---@param opts Portal.SearchOptions
            ---@return Portal.Query
            query = function(opts)
                local Settings = require("portal.settings")
                return generator(opts or {}, Settings)
            end,

            ---@param opts Portal.SearchOptions
            ---@return Portal.Content[]
            search = function(opts)
                local Portal = require("portal")
                local query = Builtin[name].query(opts)
                return Portal.search(query)
            end,

            ---@param opts Portal.SearchOptions
            tunnel = function(opts)
                local Portal = require("portal")
                local query = Builtin[name].query(opts)
                Portal.tunnel(query)
            end,

            ---@param opts Portal.SearchOptions
            tunnel_forward = function(opts)
                Builtin[name].tunnel(vim.tbl_extend("force", opts or {}, { direction = "forward" }))
            end,

            ---@param opts Portal.SearchOptions
            tunnel_backward = function(opts)
                Builtin[name].tunnel(vim.tbl_extend("force", opts or {}, { direction = "backward" }))
            end,
        }, {
            __call = function(t, ...)
                t.tunnel(...)
            end,
        })

        rawset(t, name, builtin)

        return builtin
    end,
})

return Builtin
