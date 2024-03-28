return require("portal.extension").register({
    name = "quickfix",

    ---@return Portal.Result[] results, Portal.QueryOptions defaults
    generate = function()
        local quickfix = vim.fn.getqflist()

        ---@class Portal.QuickfixItem
        ---@field bufnr integer
        ---@field lnum integer
        ---@field col integer

        local defaults = {
            ---@param item Portal.QuickfixItem
            ---@return boolean
            filter = function(item)
                return vim.api.nvim_buf_is_valid(item.bufnr)
            end,
        }

        return quickfix, defaults
    end,

    ---@param _ integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content
    transform = function(_, extended_result)
        local result = extended_result.result

        return {
            buffer = result.bufnr,
            cursor = { result.lnum, result.col },
        }
    end,

    select = function(content)
        vim.api.nvim_win_set_buf(0, content.buffer)
        vim.api.nvim_win_set_cursor(0, { content.cursor[1], content.cursor[2] })
    end,
})
