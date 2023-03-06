---@type Portal.QueryGenerator
local function generator(opts, settings)
    local Iterator = require("portal.iterator")
    local Search = require("portal.search")

    local ok, _ = require("grapple")
    if not ok then
        require("portal.log").error("Unable to load 'grapple'. Please ensure that grapple.nvim is installed.")
    end

    local tags = require("grapple").tags()

    opts = vim.tbl_extend("force", {
        direction = "forward",
        max_results = #settings.labels,
    }, opts or {})

    if settings.max_results then
        opts.max_results = math.min(opts.max_results, settings.max_results)
    end

    -- stylua: ignore
    local iter = Iterator:new(tags)
        :take(settings.lookback)

    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end

    iter = iter:map(function(v, _)
        local buffer
        if vim.fn.bufexists(v.file_path) ~= 0 then
            buffer = vim.fn.bufnr(v.file_path)
        else
            buffer = vim.fn.bufadd(v.file_path)
        end

        if buffer == vim.fn.bufnr() then
            return nil
        end

        return {
            type = "grapple",
            buffer = buffer,
            cursor = { row = v.cursor[1], col = v.cursor[2] },
            select = function(content)
                require("grapple").select({ key = content.key })
            end,
            key = v.key,
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
