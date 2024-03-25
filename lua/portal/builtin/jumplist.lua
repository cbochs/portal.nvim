return require("portal.extension").register({
    name = "jumplist",

    ---@return Portal.Result[] results, Portal.QueryOptions? defaults
    generate = function()
        local Iter = require("portal.iterator")

        local jumplist, position = unpack(vim.fn.getjumplist())

        ---@cast jumplist vim.fn.getjumplist.ret.item[]
        ---@cast position integer

        -- Current position is 0-indexed, convert to a 1-indexed table index
        position = position + 1

        ---@param index integer
        ---@param item vim.fn.getjumplist.ret.item
        local function extend_jumplist(index, item)
            ---@class Portal.JumplistResult
            local result = {
                item = item,
                dist = math.abs(index - position),
            }

            return result
        end

        -- stylua: ignore
        jumplist = Iter.iter(jumplist)
            :enumerate()
            :map(extend_jumplist)
            :totable()

        ---@type Portal.QueryOptions
        local defaults = {
            reverse = true,
            filter = function(content)
                return vim.api.nvim_buf_is_valid(content.buffer)
            end,
        }

        return jumplist, defaults
    end,

    ---@param _ integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content
    transform = function(_, extended_result)
        ---@type Portal.JumplistResult
        local result = extended_result.result
        local opts = extended_result.opts

        ---@type Portal.Content
        local content = {
            type = "jumplist",
            buffer = result.item.bufnr,
            cursor = { result.item.lnum, result.item.col },
            extra = {
                reverse = opts.reverse,
                dist = result.dist,
            },
        }

        return content
    end,

    ---@param content Portal.Content
    select = function(content)
        -- stylua: ignore
        local keycode = content.extra.reverse
            and vim.api.nvim_replace_termcodes("<c-i>", true, false, true)
            or vim.api.nvim_replace_termcodes("<c-o>", true, false, true)

        vim.api.nvim_feedkeys(content.extra.dist .. keycode, "n", false)
    end,
})
