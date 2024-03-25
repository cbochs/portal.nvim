local Iter = require("portal.iterator")
local Query = require("portal.query")
local Window = require("portal.window")

local Search = {}

---@param queries Portal.Query | Portal.Query[]
---@param slots? Portal.Slots
---@param opts? Portal.QueryOptions
---@return table
function Search.search(queries, slots, opts)
    vim.validate({
        queries = { queries, "table" },
        slots = { slots, { "number", "function", "table", "nil" } },
        opts = { opts, { "table", "nil" } },
    })

    -- Wrap a single query as a single item list
    if getmetatable(queries) == Query then
        queries = { queries }
    end

    -- stylua: ignore
    local results = Iter.iter(queries)
        :map(function(q) return q, slots, opts end)
        :map(Query.search)
        :flatten()
        :totable()

    return results
end

---@param results Portal.Content[]
---@param labels string[]
---@param win_opts vim.api.keyset.win_config
---@return Portal.Window[]
function Search.portals(results, labels, win_opts)
    vim.validate({
        results = { results, "table" },
        labels = { labels, "table" },
        win_opts = { win_opts, "table" },
    })

    if vim.tbl_isempty(results) then
        return {}
    end

    local function compute_max_index()
        return math.min(math.max(unpack(vim.tbl_keys(results))), #labels)
    end

    local function compute_initial_offset()
        local row_offset = 0

        local height_step = win_opts.height + 2
        local total_height = vim.tbl_count(results) * height_step

        local win_height = vim.api.nvim_win_get_height(0)
        local win_current_line = vim.fn.line(".")
        local win_top_line = vim.fn.line("w0")
        local win_bottom_line = win_top_line + win_height

        local line_difference = win_bottom_line - win_current_line

        if line_difference < total_height then
            row_offset = line_difference - total_height
        end

        return row_offset
    end

    local windows = {}

    local cur_row = 0
    local max_index = compute_max_index()
    local row_offset = compute_initial_offset()

    for i = 1, max_index do
        -- stylua: ignore
        if not results[i] then goto continue end

        local result = results[i]

        cur_row = cur_row + 1
        win_opts = vim.deepcopy(win_opts)
        win_opts.row = row_offset + (cur_row - 1) * (win_opts.height + 2)

        if type(win_opts.title) == "function" then
            win_opts.title = win_opts.title(result)
        else
            win_opts.title = nil
            win_opts.title_pos = nil
        end

        local window = Window.new(result, labels[i], win_opts)

        table.insert(windows, window)

        ::continue::
    end

    return windows
end

return Search
