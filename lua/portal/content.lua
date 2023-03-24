---@class Portal.Content
---@field type string
---@field buffer integer
---@field cursor { row: integer, col: integer }
---@field callback fun(c: Portal.Content)
---@field extra table
local Content = {}
Content.__index = Content

function Content:new(content)
    assert(content.buffer, ("Portal: invalid content.buffer %s"):format(vim.inspect(content.buffer)))
    assert(
        content.cursor and content.cursor.row and content.cursor.col,
        ("Portal: invalid content.cursor %s"):format(vim.inspect(content.cursor))
    )
    assert(
        type(content.callback) == "function",
        ("Portal: invalid content.callback %s"):format(vim.inspect(content.callback))
    )

    content.extra = content.extra or {}
    setmetatable(content, self)

    return content
end

function Content:select()
    return self.callback(self)
end

return Content
