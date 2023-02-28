local Iterator = require("portal.iterator")

local Search = {}

---@class Portal.SearchOptions
---@field filter Portal.SearchQuery
---@field direction Portal.Direction
---@field start number
---@field max_results number

---@alias Portal.SearchQuery Portal.Predicate[]
---@alias Portal.SearchResult any[]

---@enum Portal.Direction
Search.direction = {
    forward = "forward",
    backward = "backward",
}

---@param list table
---@param opts Portal.SearchOptions
---@return Portal.Iterator
function Search.iter(list, opts)
    opts = opts or {}

    -- stylua: ignore
    local iter = Iterator:new(list)

    if opts.direction == Search.direction.backward then
        iter = iter:reverse()
    end
    if opts.start then
        iter = iter:start_at(opts.start)
    end
    if opts.filter then
        iter = iter:filter(opts.filter)
    end
    if opts.max_results then
        iter = iter:take(opts.max_results)
    end

    return iter
end

---@param iter Portal.Iterator
---@param query Portal.SearchQuery
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
                break
            end
        end
        return acc
    end, {
        matches = {},
        matched_predicates = {},
    })

    return results.matches
end

return Search
