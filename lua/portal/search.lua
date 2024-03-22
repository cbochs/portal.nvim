local Window = require("portal.window")
local log = require("portal.log")

local Search = {}

---@class Portal.SearchOptions
---@field start integer
---@field direction Portal.Direction
---@field max_results integer
---@field filter Portal.SearchPredicate
---@field slots Portal.SearchPredicate[] | nil

---@class Portal.Query
---@field source Portal.Iterator
---@field slots Portal.SearchPredicate[] | nil

---@alias Portal.SearchPredicate fun(v: Portal.Content): boolean

---@enum Portal.Direction
Search.direction = {
    forward = "forward",
    backward = "backward",
}

---@generic T
---@param query Portal.Query
---@return T[]
function Search.search(query)
    local slots = query.slots
    if not slots then
        return query.source:collect()
    end

    if type(slots) == "function" then
        slots = { slots }
    end

    local results = query.source:reduce(function(acc, value)
        for i, predicate in ipairs(slots) do
            if not acc[i] and predicate(value) then
                acc[i] = value
                break
            end
        end
        return acc
    end, {})

    return results
end

---@param results Portal.Content[]
---@param labels string[]
---@param window_options Portal.WindowOptions
---@return Portal.Window[]
function Search.portals(results, labels, window_options)
    if vim.tbl_isempty(results) then
        vim.notify("Portal: empty search results")
        return {}
    end
    if vim.tbl_count(results) > vim.tbl_count(labels) then
        log.warn("Search.open: found more results than available labels.")
    end

    local function window_title(result)
        local title = vim.fs.basename(vim.api.nvim_buf_get_name(result.buffer))
        if title == "" then
            title = "Result"
        end
        return ("[%s] %s"):format(result.type, title)
    end

    local function compute_max_index()
        return math.min(math.max(unpack(vim.tbl_keys(results))), #labels)
    end

    local function compute_initial_offset()
        local row_offset = 0

        local height_step = window_options.height + 2
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
        window_options = vim.deepcopy(window_options)
        window_options.row = row_offset + (cur_row - 1) * (window_options.height + 2)

        if vim.fn.has("nvim-0.9") == 1 then
            window_options.title = window_title(result)
        end

        local window = Window:new(labels[i], result, window_options)

        table.insert(windows, window)

        ::continue::
    end

    return windows
end

---@param windows Portal.Window[]
---@param escape_keys string[]
---@return Portal.Window | nil
function Search.select(windows, escape_keys)
    if vim.tbl_isempty(windows) then
        return
    end

    while true do
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok then
            break
        end
        for _, key in pairs(escape_keys) do
            if char == key then
                goto done
            end
        end
        for _, window in ipairs(windows) do
            if window:has_label(char) then
                return window
            end
        end
    end
    ::done::
end

return Search
