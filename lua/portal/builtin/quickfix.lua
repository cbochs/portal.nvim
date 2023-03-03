---@type Portal.QueryGenerator
return function(opts, settings)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local quickfix = vim.fn.getqflist()

    opts = vim.tbl_extend("force", {
        direction = "forward",
        max_results = math.min(settings.max_results, #settings.labels),
    }, opts or {})

    -- stylua: ignore
    local iter = Iterator:new(quickfix)
        :take(settings.lookback)

    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, _)
        return {
            type = "quickfix",
            buffer = v.bufnr,
            cursor = { row = v.lnum, col = v.col },
            select = function(content)
                vim.api.nvim_win_set_buf(0, content.buffer)
                vim.api.nvim_win_set_cursor(0, { content.cursor.row, content.cursor.col })
            end,
        }
    end)

    iter = iter:filter(settings.filter)

    if opts.filter then
        iter = iter:filter(opts.filter)
    end
    if not opts.slots then
        iter = iter:take(opts.max_results)
    end

    return {
        source = iter,
        slots = opts.slots,
    }
end
