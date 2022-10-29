local M = {}

local marks = {}

function M.mark()
    marks[vim.fn.bufnr()] = true
end

function M.unmark()
    marks[vim.fn.bufnr()] = nil
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
    buffer = buffer or vim.fn.bufnr()
    return marks[buffer] or false
end

return M
