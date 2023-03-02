return {
    ---@type Portal.Generator
    generate = function(opts, settings)
        local Iterator = require("portal.iterator")
        local Search = require("portal.search")

        local quickfix = vim.fn.getqflist()

        opts = vim.tbl_extend("force", {
            start = 1,
            direction = "forward",
            max_results = math.min(settings.max_results, #settings.labels),
            query = nil,
        }, opts)

        -- stylua: ignore
        local iter = Iterator:new(quickfix)
            :start_at(opts.start)
            :take(settings.lookback)

        if opts.direction == Search.direction.backward then
            iter = iter:reverse()
        end

        iter = iter:map(function(v, _)
            return {
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
        if not opts.query then
            iter = iter:take(opts.max_results)
        end

        return {
            iter = iter,
            query = opts.query,
        }
    end,
}
