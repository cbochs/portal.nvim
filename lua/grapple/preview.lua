local M = {}

--- @class Grapple.Float
--- @field buffer integer
--- @field window integer
--- @field extmark integer

--- @type Grapple.Float[]
local floats = {}

local float_namespace = vim.api.nvim_create_namespace("")

--- @param jump Grapple.Jump
--- @param decorations Grapple.Decorations
--- @return integer
local function preview_buffer(jump, decorations)
    if not vim.api.nvim_buf_is_valid(jump.buffer) then
        return vim.api.nvim_create_buf(false, true)
    end

    if not vim.api.nvim_buf_is_loaded(jump.buffer) then
        vim.fn.bufload(jump.buffer)
        return jump.buffer
    end

    return jump.buffer
end

--- @param jump Grapple.Jump
--- @param buffer integer
--- @param decorations Grapple.Decorations
--- @return integer
local function preview_window(jump, buffer, decorations)
    local cursor = {
        math.min(jump.row, vim.api.nvim_buf_line_count(buffer)),
        jump.col
    }

    -- See :h vim.api.nvim_open_win
    -- Parameters: {buffer}, {enter}, {config}
    local window = vim.api.nvim_open_win(buffer, false, decorations.window())

    if vim.api.nvim_buf_get_name(buffer) ~= "" then
        vim.api.nvim_win_set_cursor(window, cursor)
    end

    return window
end

--- @param jump Grapple.Jump
--- @param buffer integer
--- @param decorations Grapple.Decorations
--- @return integer
local function preview_extmark(jump, buffer, decorations)
    local row = jump.row - 1
    local col = 0

    if vim.api.nvim_buf_get_name(buffer) == "" then
        return -1
    end

    local cursor = { row, col }
    local extmarks = vim.api.nvim_buf_get_extmarks(
        buffer, float_namespace, cursor, cursor, {
        details = true
    })

    local extmark_id = nil
    if #extmarks > 0 then
        local extmark = extmarks[1]
        local details = extmark[4]
        extmark_id = extmark[1]

        vim.api.nvim_buf_set_extmark(
            buffer, float_namespace, row, col,
            vim.tbl_extend("keep", { id = extmark_id }, decorations.extmark(details))
        )
    else
        -- See :h vim.api.nvim_buf_set_extmark
        -- Parameters: {buffer}, {namespace}, {row}, {col}, {opts}
        extmark_id = vim.api.nvim_buf_set_extmark(
            buffer, float_namespace, row, col,
            decorations.extmark()
        )
    end

    return extmark_id
end

--- @param jumps Grapple.Jump[]
--- @param decorator Grapple.Decorator
function M.preview_jumps(jumps, decorator)
    M.clear()

    for index, jump in pairs(jumps) do
        local decorations = decorator(index, jump)
        local buffer = preview_buffer(jump, decorations)
        local window = preview_window(jump, buffer, decorations)
        local extmark = preview_extmark(jump, buffer, decorations)

        --- @type Grapple.Float
        local float = {
            buffer = buffer,
            window = window,
            extmark = extmark
        }

        table.insert(floats, float)
    end

    -- Force UI to redraw to avoid user input blocking preview windows from
    -- showing up.
    vim.cmd("redraw")
end

function M.clear()
    for _, float in pairs(floats) do
        vim.api.nvim_buf_del_extmark(float.buffer, float_namespace, float.extmark)
        if vim.api.nvim_buf_get_name(float.buffer) == "" then
            vim.api.nvim_buf_delete(float.buffer, { force = true })
        end
        if vim.api.nvim_win_is_valid(float.window) then
            vim.api.nvim_win_close(float.window, true)
        end
    end
    floats = {}
end

return M
