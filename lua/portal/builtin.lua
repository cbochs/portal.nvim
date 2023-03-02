local log = require("portal.log")

local Builtin = {}

---@alias Portal.QueryGenerator fun(o: Portal.SearchOptions, s: Portal.Settings): Portal.Query | Portal.Query[]
---@alias Portal.Tunnel fun(o: Portal.SearchOptions)

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        ---@type boolean, Portal.QueryGenerator
        local ok, generator = pcall(require, ("portal.builtin.%s"):format(name))
        if not ok then
            log.warn(("Unable to load builtin %s"):format(name))
            return
        end

        local builtin = {
            query = function(opts)
                local Settings = require("portal.settings")
                return generator(opts or {}, Settings)
            end,

            ---@type Portal.Tunnel
            tunnel = function(opts)
                local Portal = require("portal")
                local query = Builtin[name].query(opts)
                Portal.tunnel(query)
            end,

            ---@type Portal.Tunnel
            tunnel_forward = function(opts)
                Builtin[name].tunnel(vim.tbl_extend("force", opts or {}, { direction = "forward" }))
            end,

            ---@type Portal.Tunnel
            tunnel_backward = function(opts)
                Builtin[name].tunnel(vim.tbl_extend("force", opts or {}, { direction = "backward" }))
            end,
        }

        rawset(t, name, builtin)

        return builtin
    end,
})

return Builtin
