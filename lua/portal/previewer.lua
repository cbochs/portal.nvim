local config = require("portal.config")
local types = require("portal.types")

local M = {}

--- @class Portal.Extmark
--- @field buffer integer
--- @field namespace integer
--- @field row integer
--- @field col integer
--- @field details table

--- @param buffer integer
--- @return boolean
local function ensure_loaded(buffer)
    if not vim.api.nvim_buf_is_valid(buffer) then
        return false
    end
    if not vim.api.nvim_buf_is_loaded(buffer) then
        vim.fn.bufload(buffer)
    end
    return true
end

--- @param buffer integer
--- @param namespace integer
--- @param start integer[]
--- @param _end integer[]
--- @return Portal.Extmark
local function get_extmarks(buffer, namespace, start, _end)
    -- See :h vim.api.nvim_buf_get_extmarks
    -- Parameters: {buffer}, {namespace}, {start}, {end}, {opts}
    -- Returns: list of ( {id}, {row}, {col}, {details} )
    local result = vim.api.nvim_buf_get_extmarks(buffer, namespace, start, _end, { details = true })

    local extmarks = {}
    for _, extmark in pairs(result) do
        table.insert(extmarks, {
            row = extmark[2],
            col = extmark[3],
            details = vim.tbl_extend("error", { id = extmark[1] }, extmark[4])
        })
    end
    return extmarks
end

--- @param extmark Portal.Extmark
local function create_or_edit_extmark(extmark)
    local cursor = { extmark.row, extmark.col }
    local old_extmark = get_extmarks(extmark.buffer, extmark.namespace, cursor, cursor)[1]
    if old_extmark ~= nil then
        local text = extmark.details.virt_text[1][1]
        local old_text = old_extmark.details.virt_text[1][1]
        local combined = old_text .. " " .. text
        extmark.details.virt_text[1][1] = combined

        extmark.details = vim.tbl_extend("force", old_extmark.details or {}, extmark.details)
    end

    vim.api.nvim_buf_set_extmark(extmark.buffer, extmark.namespace, extmark.row, extmark.col, extmark.details)
end

--- @param jumps Portal.Jump[]
--- @param namespace Portal.Namespace
--- @return Portal.Label[]
function M.label(jumps, namespace)
    local labels = {}

    for index, jump in pairs(jumps) do
        if jump.direction == types.Direction.NONE then
            goto continue
        end
        if not ensure_loaded(jump.buffer) then
            goto continue
        end

        local label = config.jump.labels[index]
        labels[index] = label

        local function clamp(value, min, max)
            return math.max(math.min(value, max), min)
        end

        local extmark = {
            buffer = jump.buffer,
            namespace = namespace,
            row = clamp(jump.row, 1, vim.api.nvim_buf_line_count(jump.buffer)) - 1,
            col = 0,
            details = {
                virt_text = {{ "[" .. label .. "]", "LeapLabelPrimary" }},
                virt_text_pos = "overlay"
            }
        }
        create_or_edit_extmark(extmark)

        ::continue::
    end

    return labels
end

--- @param jumps Portal.Jump[]
--- @param labels Portal.Label[]
--- @param namespace Portal.Namespace
--- @return Portal.Portal[]
function M.open(jumps, labels, namespace)
    --- @type Portal.Portal
    local portals = {}

    local offset = 0

    for index, jump in pairs(jumps) do
        local windows = {}

        local empty_portal = jump.direction == types.Direction.NONE
        local render_title = not empty_portal or config.window.title.render_empty
        local render_portal = not empty_portal or config.window.portal.render_empty

        local title_options  = vim.deepcopy(config.window.title.options)
        local portal_options = vim.deepcopy(config.window.portal.options)

        if not empty_portal then
            if not ensure_loaded(jump.buffer) then
                goto continue
            end
        end

        if render_title then
            title_options.row = offset
            offset = offset + title_options.height + 1

            if render_portal then
                title_options.height = title_options.height + portal_options.height
            end

            local title = jump.query.name
            if not empty_portal then
                title = title .. " | " .. vim.fs.basename(vim.api.nvim_buf_get_name(jump.buffer))
            end

            local title_buffer = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_option(title_buffer, "bufhidden", "wipe")
            vim.api.nvim_buf_set_lines(title_buffer, 0, -1, false, { title })

            local title_window = vim.api.nvim_open_win(title_buffer, false, title_options)
            table.insert(windows, title_window)
        end

        if render_portal then
            portal_options.row = offset
            offset =  offset + portal_options.height + 1

            local portal_window = vim.api.nvim_open_win(jump.buffer, false, portal_options)
            table.insert(windows, portal_window)

            vim.api.nvim_win_set_cursor(portal_window, {
                math.min(jump.row, vim.api.nvim_buf_line_count(jump.buffer)),
                jump.col
            })
        end

        offset = offset + 1

        local portal = {
            jump = jump,
            label = labels[index],
            windows = windows,
            namespace = namespace,
        }

        table.insert(portals, portal)

        ::continue::
    end

    return portals
end

--- @param portals Portal.Portal[]
function M.close(portals)
    for _, portal in pairs(portals) do
        for _, window in pairs(portal.windows) do
            if vim.api.nvim_win_is_valid(window) then
                vim.api.nvim_win_close(window, true)
            end
        end

        if portal.jump.buffer ~= nil and vim.api.nvim_buf_is_valid(portal.jump.buffer) then
            vim.api.nvim_buf_clear_namespace(portal.jump.buffer, portal.namespace, 0, -1)
        end
    end
end

return M
