local Window = require("portal.window")
local log = require("portal.log")

local Search = {}

---@class Portal.SearchOptions
---@field start integer
---@field direction Portal.Direction
---@field max_results integer
---@field filter Portal.SearchPredicate
---@field query Portal.Query[]

---@class Portal.Query
---@field source Portal.Iterator
---@field predicates Portal.SearchPredicate[] | nil

---@alias Portal.SearchPredicate fun(v: Portal.WindowContent): boolean

---@enum Portal.Direction
Search.direction = {
    forward = "forward",
    backward = "backward",
}

---@generic T
---@param query Portal.Query
---@return T[]
function Search.search(query)
    local predicates = query.predicates
    if not predicates then
        return query.source:collect()
    end

    if type(predicates) == "function" then
        predicates = { predicates }
    end

    local results = query.source:reduce(function(acc, value)
        for i, predicate in ipairs(predicates) do
            if not acc.matched_predicates[predicate] and predicate(value) then
                acc.matched_predicates[predicate] = true
                acc.matches[i] = value
            end
        end
        return acc
    end, {
        matches = {},
        matched_predicates = {},
    })

    return results.matches
end

---@param results Portal.WindowContent[]
---@param labels string[]
---@param window_options Portal.WindowOptions
---@return Portal.Window[]
function Search.open(results, labels, window_options)
    if vim.tbl_isempty(results) then
        vim.notify("Portal: empty search results")
        return {}
    end
    if vim.tbl_count(results) > vim.tbl_count(labels) then
        log.warn("Search.open: found more results than available labels.")
    end

    local windows = {}

    local max_index = math.max(unpack(vim.tbl_keys(results)))
    local cur_row = 0

    for i = 1, max_index do
        local result = results[i]
        if not result then
            goto continue
        end

        cur_row = cur_row + 1
        window_options = vim.deepcopy(window_options)
        window_options.row = (cur_row - 1) * (window_options.height + 2)

        if vim.fn.has("nvim-0.9") == 1 then
            local title = vim.fs.basename(vim.api.nvim_buf_get_name(result.buffer))
            if title == "" then
                title = "Result"
            end
            window_options.title = ("[%s] %s"):format(i, title)
        end

        local window = Window:new(result, window_options)
        window:open()
        window:label(labels[i])

        table.insert(windows, window)

        ::continue::
    end

    -- Force UI to redraw to ensure windows appear before user input
    vim.cmd("redraw")

    return windows
end

---@param windows Portal.Window[]
---@param escape_keys string[]
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
                window:select()
                goto done
            end
        end
    end
    ::done::

    for _, window in ipairs(windows) do
        window:close()
    end
end

return Search
