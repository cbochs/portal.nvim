local input = {}

---@param escape_keys? string[]
---@return string | nil
function input.get_label(escape_keys)
    escape_keys = escape_keys or require("portal.settings").escape

    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
        return nil
    end

    if vim.tbl_contains(escape_keys, char) then
        return nil
    end

    return char
end

return input
