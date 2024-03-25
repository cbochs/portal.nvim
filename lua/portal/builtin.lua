local Query = require("portal.query")

---@type table<string, Portal.Builtin>
local Builtin = {}

setmetatable(Builtin, {
    __index = function(t, name)
        if rawget(t, name) then
            return rawget(t, name)
        end

        ---@type Portal.Generator
        local generator
        if pcall(require, ("portal.builtin.%s"):format(name)) then
            -- Portal provides this as a builtin
            generator = require(("portal.builtin.%s"):format(name))
        elseif pcall(require, ("portal.extension.%s"):format(name)) then
            -- Plugin provides this as an extension
            generator = require(("portal.extension.%s"):format(name))
        end

        if not generator then
            return
        end

        ---@class Portal.Builtin
        local builtin = setmetatable({
            generator = generator,

            ---@param opts? Portal.QueryOptions
            ---@return Portal.Query
            prepare = function(opts)
                return Query.new(generator):prepare(opts)
            end,

            ---@deprecated
            ---@param opts? Portal.QueryOptions
            ---@return Portal.Query
            query = function(opts)
                vim.notify("Portal: 'query' has been renamed to 'prepare'", vim.log.levels.WARN)
                return Query.new(generator):prepare(opts)
            end,

            ---@param slots? Portal.Slots
            ---@param opts? Portal.QueryOptions
            ---@return Portal.Content[]
            search = function(slots, opts)
                local query = Query.new(generator)
                return require("portal").search(query, slots, opts)
            end,

            ---@param opts? Portal.Options
            tunnel = function(opts)
                local query = Query.new(generator)
                require("portal").tunnel(query, opts)
            end,

            ---@param opts? Portal.Options
            tunnel_forward = function(opts)
                local query = Query.new(generator)
                opts = vim.tbl_deep_extend("force", opts or {}, { query = { reverse = false } })
                require("portal").tunnel(query, opts)
            end,

            ---@param opts? Portal.Options
            tunnel_backward = function(opts)
                local query = Query.new(generator)
                opts = vim.tbl_deep_extend("force", opts or {}, { query = { reverse = true } })
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
