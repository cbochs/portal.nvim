local M = {}

---@param jump Portal.Jump
---@return boolean
local function is_marked(jump)
    local query = require("portal.query")
    if not query.valid(jump) then
        return
    end
    local buffer_name = require("harpoon.utils").normalize_path(vim.api.nvim_buf_get_name(jump.buffer))
    local mark = require("harpoon.mark").get_marked_file(buffer_name)
    return query.different(jump) and mark ~= nil
end

function M.register()
    local ok, _ = pcall(require, "grapple")
    if not ok then
        require("portal.log").warn("Unable to register query item. Please check that harpoon is installed.")
        return
    end

    require("portal.query").register("harpoon", is_marked, {
        name = "Harpoon",
        name_short = "H",
    })
end

return M
