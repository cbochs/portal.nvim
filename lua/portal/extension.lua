local Extension = {}

---@class Portal.Extension
---@field name string
---@field generate Portal.Generator
---@field transform Portal.Transformer
---@field select fun(c: Portal.Content)

---@type table<string, Portal.Extension>
Extension.extensions = {}

---@param extension Portal.Extension
---@return Portal.Extension
function Extension.register(extension)
    if Extension.extensions[extension.name] then
        return Extension.extensions[extension.name]
    end

    ---@type Portal.Extension
    Extension.extensions[extension.name] = {
        name = extension.name,

        generate = extension.generate,

        transform = function(...)
            local content = extension.transform(...)
            if content then
                content.type = extension.name
                content.select = extension.select
                return content
            end
        end,

        select = extension.select,
    }

    return Extension.extensions[extension.name]
end

return Extension
