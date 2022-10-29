local M = {}

--- @alias Grapple.Predicate fun(jump: Grapple.Jump): boolean

local predicates = {}

--- @param predicate Grapple.Predicate
function M.register(predicate)
    predicates[predicate] = true
end

--- @param jump Grapple.Jump
--- @return boolean
function M.is_valid(jump)
    return vim.api.nvim_buf_is_valid(jump.buffer)
end

--- @param jump Grapple.Jump
--- @return boolean
function M.is_not_same_buffer(jump)
    return jump.buffer ~= vim.fn.bufnr()
end

--- @param jump Grapple.Jump
--- @return boolean
function M.is_marked(jump)
    local mark = require("grapple.mark")
    return M.is_valid(jump)
        and M.is_not_same_buffer(jump)
        and mark.exists(jump.buffer)
end

--- @param jump Grapple.Jump
--- @return boolean
function M.is_modified(jump)
    return M.is_valid(jump)
        and M.is_not_same_buffer(jump)
        and vim.api.nvim_buf_get_option(jump.buffer, "modified")
end

setmetatable(M, {
    __index = function(index)
        return predicates[index]
    end
})

return M
