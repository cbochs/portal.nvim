---@class Portal.Window
---@field content Portal.WindowContent
---@field options Portal.WindowOptions
---@field state Portal.WindowState
local Window = {}

---@class Portal.WindowContent
---@field buffer number
---@field cursor { row: number, col: number }

---@class Portal.WindowOptions
---@field title string
---@field relative string
---@field width number
---@field height number
---@field row number
---@field col number
---@field border string | table
---@field noautocmd boolean

---@class Portal.WindowState
---@field window integer | any
---@field buffer integer | any
---@field extmark integer | any

local namespace = vim.api.nvim_create_namespace("portal")

---@param content Portal.WindowContent
---@param options Portal.WindowOptions
---@return Portal.Window
function Window:new(content, options)
    local window = {
        content = content,
        options = options,
        state = {},
    }
    setmetatable(window, self)
    return window
end

function Window:open()
    self.state.buffer = self.content.buffer
    -- vim.api.nvim_buf_set_option(self.buffer, "bufhidden", "wipe")
    -- vim.api.nvim_buf_set_option(self.buffer, "filetype", "portal")

    self.state.window = vim.api.nvim_open_win(self.state.buffer, false, self.options)

    local cursor = { self.content.cursor.row, self.content.cursor.col }
    vim.api.nvim_win_set_cursor(self.state.window, cursor)
end

-- luacheck: ignore
function Window:label() end

function Window:close()
    if vim.api.nvim_win_is_valid(self.state.window) then
        vim.api.nvim_win_close(self.state.window, true)
    end
    if vim.api.nvim_buf_is_valid(self.state.buffer) then
        vim.api.nvim_buf_clear_namespace(self.state.buffer, namespace, 0, -1)
    end
    self.state = {}
end

return Window
