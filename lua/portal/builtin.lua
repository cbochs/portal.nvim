local Query = require("portal.query")

---@type table<string, Portal.Builtin>
local Builtin = {}

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        ---@type Portal.Extension
        local extension
        if pcall(require, ("portal.builtin.%s"):format(name)) then
            -- Portal provides this as a builtin
            extension = require(("portal.builtin.%s"):format(name))
        elseif pcall(require, ("portal.extension.%s"):format(name)) then
            -- Plugin provides this as an extension
            extension = require(("portal.extension.%s"):format(name))
        end

        if not extension then
            return
        end

        ---@class Portal.Builtin
        local builtin = setmetatable({
            extension = extension,

            ---@param opts? Portal.QueryOptions
            ---@return Portal.Query
            query = function(opts)
                return Query.new(extension.generate, extension.transform):prepare(opts)
            end,

            ---@param opts? Portal.SearchOptions
            ---@return Portal.Content[]
            search = function(opts)
                local query = Query.new(extension.generate, extension.transform)
                return require("portal").search(query, opts)
            end,

            ---@param opts? Portal.Options
            tunnel = function(opts)
                local query = Query.new(extension.generate, extension.transform)
                require("portal").tunnel(query, opts)
            end,

            ---@param opts? Portal.Options
            tunnel_forward = function(opts)
                local query = Query.new(extension.generate, extension.transform)
                opts = vim.tbl_deep_extend("force", opts or {}, { search = { reverse = false } })
                require("portal").tunnel(query, opts)
            end,

            ---@param opts? Portal.Options
            tunnel_backward = function(opts)
                local query = Query.new(extension.generate, extension.transform)
                opts = vim.tbl_deep_extend("force", opts or {}, { search = { reverse = true } })
                require("portal").tunnel(query, opts)
            end,
        }, {
            __call = function(tbl, ...)
                return tbl.tunnel(...)
            end,
        })

        rawset(t, name, builtin)

        return builtin
    end,
})

return Builtin
