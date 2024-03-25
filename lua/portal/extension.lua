---@class Portal.Extension
---@field name string
---@field generate fun(): Portal.Result[], Portal.QueryOptions?
---@field transform fun(r: Portal.Result, index: integer): Portal.Content
---@field select fun(c: Portal.Content)
local Extension = {}

---@alias Portal.Result any

---@class Portal.ExtendedResult
---@field result Portal.Result
---@field opts Portal.QueryOptions

---@class Portal.Content
---@field type string
---@field buffer? integer
---@field path? string
---@field cursor integer[] (1, 0)-indexed cursor position
---@field select? fun(c: Portal.Content)
---@field extra? table

---@class Portal.QueryOptions
---@field start? integer
---@field skip? integer
---@field reverse? boolean
---@field lookback? integer maximum number of searched items
---@field filter? Portal.Predicate

---@alias Portal.Generator fun(o?: Portal.QueryOptions): Portal.Iter
---@alias Portal.Predicate fun(c: Portal.Content): boolean

---@type table<string, Portal.Generator>
Extension.extensions = {}

---@param extension Portal.Extension
---@return Portal.Generator
function Extension.register(extension)
    if Extension.extensions[extension.name] then
        return Extension.extensions[extension.name]
    end

    ---@type Portal.Generator
    Extension.extensions[extension.name] = function(opts)
        local results, defaults = extension.generate()

        local function true_filter()
            return true
        end

        defaults = vim.tbl_deep_extend("keep", defaults or {}, {
            start = 1,
            skip = 0,
            reverse = false,
            lookback = #results,
            filter = true_filter,
        })

        opts = vim.tbl_deep_extend("keep", opts or {}, defaults)

        ---@param result Portal.Result
        ---@return Portal.ExtendedResult
        local function extend_result(result)
            ---@type Portal.ExtendedResult
            local extended = {
                result = result,
                opts = opts,
            }

            return extended
        end

        ---@param content Portal.Content
        ---@return Portal.Content
        local function embed_select(content)
            content.select = extension.select
            return content
        end

        -- Create iterator
        local Iter = require("portal.iterator")
        local iter = Iter.iter(results)

        if opts.reverse then
            iter:rev()
        end

        -- Prepare iterator
        iter:take(opts.lookback)
            :skip(opts.start - 1)
            :skip(opts.skip)
            :map(extend_result)
            :enumerate()
            :map(extension.transform)
            :map(embed_select)
            :filter(opts.filter)
            :filter(defaults.filter)

        return iter
    end

    return Extension.extensions[extension.name]
end

return Extension
