---@class Portal.Window
---@field content Portal.Content
---@field label string
---@field buf_id integer
---@field ext_id integer
---@field win_id integer
---@field win_opts vim.api.keyset.win_config
local Window = {}
Window.__index = Window

-- Create global namespace for Portal windows
local WINDOW_NS = vim.api.nvim_create_namespace("portal")

---@param content Portal.Content
---@param label string
---@param win_opts vim.api.keyset.win_config
---@return Portal.Window
function Window.new(content, label, win_opts)
    assert(content.buffer or content.path, "Portal: content must have either a buffer or path")

    return setmetatable({
        content = content,
        label = label,
        win_opts = win_opts,
    }, Window)
end

---@return boolean
function Window:is_open()
    return self.win_id ~= nil and vim.api.nvim_win_is_valid(self.win_id)
end

---@return boolean
function Window:is_closed()
    return not self:is_open()
end

function Window:select()
    self.content.select(self.content)
end

function Window:open()
    if self:is_open() then
        return
    end

    -- Create and load the window buffer
    if self.content.buffer then
        self.buf_id = self.content.buffer
    elseif self.content.path then
        self.buf_id = vim.fn.bufadd(self.content.path)
    else
        error("Portal: expected content to contain either a buffer or path")
    end

    if not vim.api.nvim_buf_is_loaded(self.buf_id) then
        -- There are various reasons "bufload" can fail. For example, if a swap
        -- file exists for the buffer and a prompt is brought up. Even if
        -- "bufload" fails, the buffer may still be loaded.
        --
        -- Reference: https://github.com/cbochs/portal.nvim/issues/20
        --

        local shortmess = vim.go.shortmess
        vim.opt.shortmess:append("A")
        pcall(vim.fn.bufload, self.buf_id)
        vim.opt.shortmess = shortmess

        if not vim.api.nvim_buf_is_loaded(self.buf_id) then
            error(string.format("Portal: failed to load: %s", self.content.buffer or self.content.path))
        end
    end

    -- Create window
    self.win_id = vim.api.nvim_open_win(self.buf_id, false, self.win_opts)

    -- Setup window highlights
    vim.api.nvim_set_option_value(
        "winhighlight",
        table.concat({
            ("%s:%s"):format("FloatTitle", "PortalTitle"),
            ("%s:%s"):format("FloatBorder", "PortalBorder"),
            ("%s:%s"):format("NormalFloat", "PortalNormal"),
        }, ","),
        { win = self.win_id }
    )

    -- Place content cursor
    local line_count = vim.api.nvim_buf_line_count(self.buf_id)
    vim.api.nvim_win_set_cursor(self.win_id, {
        math.min(self.content.cursor[1], line_count),
        self.content.cursor[2],
    })

    -- Create the window label
    local cursor = { self.content.cursor[1] - 1, self.content.cursor[2] } -- (0, 0)-indexed cursor
    local id = nil
    local row = cursor[1]
    local col = cursor[2]
    local virt_text = { { (" %s "):format(self.label), "PortalLabel" } }

    local extmarks = vim.api.nvim_buf_get_extmarks(self.buf_id, WINDOW_NS, cursor, cursor, { details = true })
    if not vim.tbl_isempty(extmarks) then
        local extmark = extmarks[1]
        id = extmark[1]
        row = extmark[2]
        col = extmark[3]
        virt_text = vim.list_extend(extmark[4].virt_text, virt_text)
    end

    self.ext_id = vim.api.nvim_buf_set_extmark(self.buf_id, WINDOW_NS, row, col, {
        id = id,
        virt_text = virt_text,
        virt_text_pos = "overlay",
        strict = false,
        spell = false,
    })
end

function Window:close()
    if self:is_closed() then
        return
    end

    if vim.api.nvim_buf_is_valid(self.buf_id) then
        vim.api.nvim_buf_clear_namespace(self.buf_id, WINDOW_NS, 0, -1)
    end

    if vim.api.nvim_win_is_valid(self.win_id) then
        vim.api.nvim_win_close(self.win_id, true)
    end

    self.buf_id = nil
    self.ext_id = nil
    self.win_id = nil
end

return Window
