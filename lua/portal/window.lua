local log = require("portal.log")

---@class Portal.Window
---@field content Portal.Content
---@field options Portal.WindowOptions
---@field state Portal.WindowState
local Window = {}
Window.__index = Window

---@class Portal.Content
---@field type string
---@field buffer integer
---@field cursor { row: integer, col: integer }
---@field select fun(c: Portal.Content)

---@class Portal.WindowOptions
---@field title string
---@field relative string
---@field width integer
---@field height integer
---@field row integer
---@field col integer
---@field border string | table
---@field noautocmd boolean

---@class Portal.WindowState
---@field window integer | any
---@field buffer integer | any
---@field extmark integer | any
---@field cursor integer[]
---@field label string

local namespace = vim.api.nvim_create_namespace("portal")

vim.api.nvim_set_hl(0, "PortalLabel", { link = "Search" })

---@param content Portal.Content
---@param options Portal.WindowOptions
---@return Portal.Window
function Window:new(content, options)
    if not content.buffer or not vim.api.nvim_buf_is_valid(content.buffer) then
        log.error(("Window.new: invalid buffer %s"):format(content.buffer))
    end
    if not content.cursor or not content.cursor.row or not content.cursor.col then
        log.error(("Window.new: cursor is not present or valid in %s"):format(vim.inspect(content)))
    end
    if not content.select then
        log.error(("Window.new: select is not present."):format(vim.inspect(content)))
    end

    local window = {
        content = content,
        options = options,
        state = nil,
    }
    setmetatable(window, self)
    return window
end

function Window:open()
    if self.state then
        log.warn("Window.open: window is already open.")
        return
    end

    self.state = {}

    self.state.buffer = self.content.buffer

    if not vim.api.nvim_buf_is_loaded(self.state.buffer) then
        -- There are various reasons "bufload" can fail. For example, if a swap
        -- file exists for the buffer and a prompt is brought up.
        -- Reference: https://github.com/cbochs/portal.nvim/issues/20
        local ok, reason = pcall(vim.fn.bufload, self.state.buffer)

        if not ok then
            log.warn(("Window.open: unable to load buffer, reason: %s"):format(reason))
        end
        if not vim.api.nvim_buf_is_loaded(self.state.buffer) then
            log.error(("Window.open: failed to load buffer %s"):format(self.state.buffer))
        end
    end

    self.state.window = vim.api.nvim_open_win(self.state.buffer, false, self.options)

    self.state.cursor = self.content.cursor
    self.state.cursor = { self.content.cursor.row, self.content.cursor.col }
    local total_lines = vim.api.nvim_buf_line_count(self.state.buffer)
    if self.state.cursor[1] > total_lines then
        self.state.cursor[1] = total_lines
        self.state.cursor[2] = 0
    end

    vim.api.nvim_win_set_cursor(self.state.window, self.state.cursor)
end

function Window:label(label)
    if not self.state then
        log.error("Window.label: window is not open.")
    end

    self.state.label = label

    local cursor = { self.state.cursor[1] - 1, self.state.cursor[2] }
    local row = cursor[1]
    local col = cursor[2]
    local id = nil
    local virt_text = { { (" %s "):format(label), "PortalLabel" } }

    local extmarks = vim.api.nvim_buf_get_extmarks(self.state.buffer, namespace, cursor, cursor, { details = true })
    if not vim.tbl_isempty(extmarks) then
        local extmark = extmarks[1]
        id = extmark[1]
        row = extmark[2]
        col = extmark[3]
        virt_text = vim.list_extend(extmark[4].virt_text, virt_text)
    end

    self.state.extmark = vim.api.nvim_buf_set_extmark(self.state.buffer, namespace, row, col, {
        id = id,
        virt_text = virt_text,
        virt_text_pos = "overlay",
        strict = false,
        spell = false,
    })
end

function Window:has_label(label)
    return self.state.label == label
end

function Window:select()
    if not self.state then
        log.warn("Window.select: window is not open.")
        return
    end
    self.content.select(self.content)
end

function Window:close()
    if not self.state then
        log.warn("Window.close: window is not open.")
        return
    end
    if vim.api.nvim_win_is_valid(self.state.window) then
        vim.api.nvim_win_close(self.state.window, true)
    end
    if vim.api.nvim_buf_is_valid(self.state.buffer) then
        -- vim.api.nvim_buf_del_extmark(self.state.buffer, namespace, self.state.extmark)
        vim.api.nvim_buf_clear_namespace(self.state.buffer, namespace, 0, -1)
    end
    self.state = nil
end

return Window
