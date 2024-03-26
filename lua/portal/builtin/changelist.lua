return require("portal.extension").register({
    name = "changelist",

    ---@return Portal.Result[] results, Portal.QueryOptions defaults
    generate = function()
        local Iter = require("portal.iterator")

        local changelist, position = unpack(vim.fn.getchangelist(0))

        ---@class Portal.ChangelistItem
        ---@field lnum integer
        ---@field col integer

        ---@cast changelist Portal.ChangelistItem[]
        ---@cast position integer

        -- Current position is 0-indexed, convert to a 1-indexed table index
        position = position + 1

        ---@param index integer
        ---@param item Portal.ChangelistItem
        ---@return Portal.ChangelistResult
        local function extend_changelist(index, item)
            ---@class Portal.ChangelistResult
            local result = {
                item = item,
                dist = math.abs(index - position),
            }

            return result
        end

        -- stylua: ignore
        changelist = Iter.iter(changelist)
            :enumerate()
            :map(extend_changelist)
            :totable()

        local defaults = {
            start = position,
            reverse = true,
            filter = function(content)
                return content.extra.dist ~= 0 and vim.api.nvim_buf_is_valid(content.buffer)
            end,
        }

        return changelist, defaults
    end,

    ---@param _ integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content
    transform = function(_, extended_result)
        ---@type Portal.ChangelistResult
        local result = extended_result.result
        local opts = extended_result.opts

        ---@type Portal.Content
        local content = {
            buffer = 0,
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
            and vim.api.nvim_replace_termcodes("g;", true, false, true)
            or vim.api.nvim_replace_termcodes("g,", true, false, true)

        vim.api.nvim_feedkeys(content.extra.dist .. keycode, "n", false)
    end,
})
