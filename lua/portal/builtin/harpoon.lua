return require("portal.extension").register({
    name = "harpoon",

    ---@return Portal.Result[] results, Portal.QueryOptions defaults
    generate = function()
        local ok, _ = pcall(require, "harpoon")
        if not ok then
            error("Portal: the 'harpoon' builtin requires the plugin 'ThePrimagen/harpoon'")
        end

        local marks = require("harpoon"):list()

        ---@type Portal.QueryOptions
        local defaults = {
            filter = function(content)
                return vim.api.nvim_buf_get_name(0) ~= content.path
            end,
        }

        return marks, defaults
    end,

    ---@param index integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content
    transform = function(index, extended_result)
        local mark = extended_result.result

        ---@type Portal.Content
        local content = {
            type = "harpoon",
            path = mark.value,
            cursor = mark.cursor or { mark.context.row or 1, mark.context.col or 0 },
            extra = {
                index = index,
            },
        }

        return content
    end,

    ---@param content Portal.Content
    select = function(content)
        require("harpoon"):list():select(content.extra.index)
    end,
})
