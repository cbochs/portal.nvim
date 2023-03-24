---@type Portal.QueryGenerator
local function generate(opts, settings)
    local Content = require("portal.content")
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local changelist, start = unpack(vim.fn.getchangelist())

    if start == #changelist then
        table.insert(changelist, {})
    end

    opts = vim.tbl_extend("force", {
        start = start + 1,
        direction = "backward",
        max_results = #settings.labels,
    }, opts or {})

    if settings.max_results then
        opts.max_results = math.min(opts.max_results, settings.max_results)
    end

    -- stylua: ignore
    local iter = Iterator:new(changelist)
        :start_at(opts.start)
        :skip(1)
        :take(settings.lookback)

    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, i)
        return Content:new({
            type = "changelist",
            buffer = 0,
            cursor = { row = v.lnum, col = v.col },
            callback = function(content)
                local keycode = vim.api.nvim_replace_termcodes("g;", true, false, true)
                if content.extra.direction == "forward" then
                    keycode = vim.api.nvim_replace_termcodes("g,", true, false, true)
                end
                vim.api.nvim_feedkeys(content.extra.distance .. keycode, "n", false)
            end,
            extra = {
                direction = opts.direction,
                distance = math.abs(opts.start - i),
            },
        })
    end)

    iter = iter:filter(function(v)
        return vim.api.nvim_buf_is_valid(v.buffer)
    end)
    if settings.filter then
        iter = iter:filter(settings.filter)
    end
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

return generate
