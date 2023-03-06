---@type Portal.QueryGenerator
local function generator(opts, settings)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local ok, _ = require("harpoon")
    if not ok then
        error("harpoon is not installed")
    end

    local marks = require("harpoon").get_mark_config().marks

    opts = vim.tbl_extend("force", {
        direction = "forward",
        max_results = #settings.labels,
    }, opts or {})

    if settings.max_results then
        opts.max_results = math.min(opts.max_results, settings.max_results)
    end

    -- stylua: ignore
    local iter = Iterator:new(marks)
        :take(settings.lookback)

    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, i)
        local buffer
        if vim.fn.bufexists(v.filename) ~= 0 then
            buffer = vim.fn.bufnr(v.filename)
        else
            buffer = vim.fn.bufadd(v.filename)
        end

        return {
            type = "harpoon",
            buffer = buffer,
            cursor = { row = v.row, col = v.col },
            select = function(content)
                require("harpoon").nav_file(content.index)
            end,
            index = i,
        }
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

return generator
