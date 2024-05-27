local log = require("portal.log")

---@class Portal.Window
---@field label string
---@field content Portal.Content
---@field options Portal.WindowOptions
---@field state Portal.WindowState
local Window = {}
Window.__index = Window

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
---@field ns integer

local namespace = vim.api.nvim_create_namespace("portal")

vim.api.nvim_set_hl(0, "PortalLabel", { link = "Search", default = true })
vim.api.nvim_set_hl(0, "PortalTitle", { link = "FloatTitle", default = true })
vim.api.nvim_set_hl(0, "PortalBorder", { link = "FloatBorder", default = true })
vim.api.nvim_set_hl(0, "PortalNormal", { link = "NormalFloat", default = true })

---@param label string
---@param content Portal.Content
---@param options Portal.WindowOptions
---@return Portal.Window
function Window:new(label, content, options)
    assert(vim.api.nvim_buf_is_valid(content.buffer), ("Portal: invalid buffer %s"):format(content.buffer))

    local window = {
        label = label,
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
    self.state.ns = vim.api.nvim_create_namespace("")
    vim.api.nvim__win_add_ns(self.state.window, self.state.ns)
    vim.api.nvim_win_set_option(
        self.state.window,
        "winhighlight",
        table.concat({
            ("%s:%s"):format("FloatTitle", "PortalTitle"),
            ("%s:%s"):format("FloatBorder", "PortalBorder"),
            ("%s:%s"):format("NormalFloat", "PortalNormal"),
        }, ",")
    )

    self.state.cursor = self.content.cursor
    self.state.cursor = { self.content.cursor.row, self.content.cursor.col }
    local total_lines = vim.api.nvim_buf_line_count(self.state.buffer)
    if self.state.cursor[1] > total_lines then
        self.state.cursor[1] = total_lines
        self.state.cursor[2] = 0
    end

    vim.api.nvim_win_set_cursor(self.state.window, self.state.cursor)
end

function Window:add_label()
    if not self.state then
        log.error("Window.label: window is not open.")
    end

    local cursor = { self.state.cursor[1] - 1, self.state.cursor[2] }
    local row = cursor[1]
    local col = cursor[2]
    local id = nil
    local virt_text = { { (" %s "):format(self.label), "PortalLabel" } }

    local extmarks = vim.api.nvim_buf_get_extmarks(self.state.buffer, self.state.ns, cursor, cursor, { details = true })
    if not vim.tbl_isempty(extmarks) then
        local extmark = extmarks[1]
        id = extmark[1]
        row = extmark[2]
        col = extmark[3]
        virt_text = vim.list_extend(extmark[4].virt_text, virt_text)
    end

    self.state.extmark = vim.api.nvim_buf_set_extmark(self.state.buffer, self.state.ns, row, col, {
        id = id,
        virt_text = virt_text,
        virt_text_pos = "overlay",
        strict = false,
        spell = false,
        scoped = true,
    })
end

function Window:has_label(label)
    return self.label == label
end

function Window:select()
    if not self.state then
        log.warn("Window.select: window is not open.")
        return
    end
    self.content:select()
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
        vim.api.nvim_buf_clear_namespace(self.state.buffer, self.state.ns, 0, -1)
        vim.api.nvim_buf_clear_namespace(self.state.buffer, namespace, 0, -1)
    end
    self.state = nil
end

return Window
