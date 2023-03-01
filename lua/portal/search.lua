local Window = require("portal.window")

local Search = {}

---@class Portal.SearchOptions
---@field start integer
---@field direction Portal.Direction
---@field max_results integer
---@field map Portal.MapFunction
---@field filter Portal.Predicate
---@field query Portal.Predicate[]

---@alias Portal.SearchResult Portal.WindowContent[]

---@generic T
---@alias Portal.MapFunction fun(v: T, i: integer): Portal.WindowContent

---@enum Portal.Direction
Search.direction = {
    forward = "forward",
    backward = "backward",
}

---@generic T
---@param iter Portal.Iterator
---@param query? Portal.Predicate | Portal.Predicate[]
---@return Portal.SearchResult
function Search.search(iter, query)
    if query then
        return Search.query(iter, query)
    end
    return iter:collect()
end

---@param iter Portal.Iterator
---@param query Portal.Predicate | Portal.Predicate[]
---@return Portal.SearchResult
function Search.query(iter, query)
    if type(query) == "function" then
        query = { query }
    end

    local results = iter:reduce(function(acc, value)
        for i, predicate in ipairs(query) do
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

---@param results Portal.SearchResult
---@param labels string[]
---@param window_options Portal.WindowOptions
---@return Portal.Window[]
function Search.open(results, labels, window_options)
    if vim.tbl_isempty(results) then
        vim.notify("Portal: empty search results")
        return {}
    end

    local windows = {}

    for i, result in ipairs(results) do
        window_options = vim.deepcopy(window_options)
        window_options.title = ("Result [%s]"):format(i)
        window_options.row = (i - 1) * (window_options.height + 2)

        local window = Window:new(result, window_options)
        window:open()
        window:label(labels[i])

        table.insert(windows, window)
    end

    -- Force UI to redraw to avoid user input blocking preview windows from
    -- showing up.
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
