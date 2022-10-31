local config = require("portal.config")
local state = require("portal.state")
local types = require("portal.types")

local M = {}

local marks = {}

function M.mark()
    local buffer_name = vim.api.nvim_buf_get_name(0)
    marks[buffer_name] = true
end

function M.unmark()
    local buffer_name = vim.api.nvim_buf_get_name(0)
    marks[buffer_name] = nil
end

function M.toggle()
    if M.exists() then
        M.unmark()
    else
        M.mark()
    end
end

--- @param buffer? integer
function M.exists(buffer)
    local buffer_name = vim.api.nvim_buf_get_name(buffer or 0)
    return marks[buffer_name] or false
end

function M.reset()
    marks = {}
end

function M.load(save_path)
    if state.file_exists(save_path) then
        marks = state.load(save_path)
    end

    if config.mark.scope ~= types.MarkScope.NONE then
        vim.api.nvim_create_augroup("PortalSave", { clear = true })
        vim.api.nvim_create_autocmd({ "VimLeave" }, {
            group = "PortalSave",
            callback = function()
                require("portal.mark").save(config.mark.save_path)
            end,
        })
    end
end

function M.save(save_path)
    if config.mark.scope == types.MarkScope.NONE then
        return
    end
    state.save(save_path, marks)
end

return M
