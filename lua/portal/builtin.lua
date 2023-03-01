local Builtin = {}

---@class Portal.GeneratorSpec
---@field name string
---@field generate Portal.Generator

---@alias Portal.Generator fun(o: Portal.SearchOptions, s: Portal.Settings): Portal.PortalOptions
---@alias Portal.Tunnel fun(o: Portal.SearchOptions)

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        local ok, spec = pcall(require, ("portal.builtin.%s"):format(name))
        if not ok then
            return -- TODO: log warning
        end

        local builtin = {
            ---@type Portal.Tunnel
            tunnel = function(opts)
                local Portal = require("portal")
                local Settings = require("portal.settings")

                opts = spec.generate(opts or {}, Settings)
                Portal.tunnel(opts)
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
