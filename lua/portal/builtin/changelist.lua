---@type Portal.QueryGenerator
local function generate(opts, settings)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local buffer = 0
    local changelist = vim.fn.getchangelist(buffer)

    opts = vim.tbl_extend("force", {
        direction = "backward",
        max_results = math.min(settings.max_results, #settings.labels),
    }, opts)

    -- stylua: ignore
    local iter = Iterator:new(changelist)
        :reverse()
        :take(settings.lookback)

    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, i)
        return {
            type = "changelist",
            buffer = v.bufnr,
            cursor = { row = v.lnum, col = v.col },
            select = function(content)
                local keycode = vim.api.nvim_replace_termcodes("g;", true, false, true)
                if content.direction == "forward" then
                    keycode = vim.api.nvim_replace_termcodes("g,", true, false, true)
                end
                vim.api.nvim_feedkeys(content.distance .. keycode, "n", false)
            end,
            direction = opts.direction,
            distance = math.abs((opts.start or 1) - i),
        }
    end)

    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    return {
        source = iter,
        slots = opts.slots,
    }
end

return generate
