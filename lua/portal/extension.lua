local Iter = require("portal.iterator")

local Extension = {}

---@class Portal.Extension
---@field name string
---@field generate fun(): Portal.Result[], Portal.QueryOptions
---@field transform fun(r: Portal.Result, i: integer): Portal.Content
---@field select fun(c: Portal.Content)

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

---@alias Portal.Predicate fun(c: Portal.Content): boolean

---@type table<string, Portal.ExtendedGenerator>
Extension.extensions = {}

---@param extension Portal.Extension
---@return Portal.ExtendedGenerator
function Extension.register(extension)
    if Extension.extensions[extension.name] then
        return Extension.extensions[extension.name]
    end

    ---@type Portal.ExtendedGenerator
    Extension.extensions[extension.name] = {
        generate = function()
            local results, defaults = extension.generate()
            return Iter.iter(results), defaults
        end,

        transform = function(...)
            local content = extension.transform(...)
            if content then
                content.select = extension.select
            end
            return content
        end,
    }

    return Extension.extensions[extension.name]
end

return Extension
