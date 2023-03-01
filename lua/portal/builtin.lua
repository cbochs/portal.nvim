local Builtin = {}

---@class Portal.GeneratorSpec
---@field name string
---@field tunnel Portal.Tunnel

---@alias Portal.Tunnel fun(opts: Portal.PortalOptions): Portal.PortalOptions

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        local ok, spec = pcall(require, ("portal.builtin.%s"):format(name))
        if not ok then
            -- TODO: log warning
            return
        end

        local builtin = {
            tunnel = spec.tunnel,
            tunnel_forward = function(opts)
                spec.tunnel(vim.tbl_extend("force", opts, { direction = "forward" }))
            end,
            tunnel_backward = function(opts)
                spec.tunnel(vim.tbl_extend("force", opts, { direction = "backward" }))
            end,
        }

        rawset(t, name, builtin)

        return builtin
    end,
})

return Builtin
