local Iter = require("portal.iterator")

---@class Portal.Query
---@field generator Portal.Generator
---@field transformer Portal.Transformer
---@field opts? Portal.SearchOptions
local Query = {}
Query.__index = Query

---@class Portal.SearchOptions
---@field start? integer the absolute starting position
---@field skip? integer
---@field reverse? boolean
---@field lookback? integer maximum number of searched items
---@field limit? integer maximum number of returned results
---@field filter? Portal.Predicate
---@field slots? Portal.Predicate | Portal.Predicate[]

---@alias Portal.Iterable table | function | Portal.Iter
---@alias Portal.Predicate fun(...): boolean
---@alias Portal.Generator fun(): Portal.Iterable, Portal.SearchOptions?
---@alias Portal.Transformer fun(i: integer, r: Portal.ExtendedResult): Portal.Content?
---@alias Portal.Result any

---@class Portal.ExtendedResult
---@field result Portal.Result
---@field opts Portal.SearchOptions

---@class Portal.Content
---@field type? string
---@field buffer? integer
---@field path? string
---@field cursor? integer[] (1, 0)-indexed cursor position
---@field select? fun(c: Portal.Content)
---@field extra? table

---@param slots Portal.Predicate | Portal.Predicate[]
---@return function
local function match_slots(slots)
    -- Wrap a single slot predicate as a list
    if type(slots) == "function" then
        slots = { slots }
    end

    return function(filled, content)
        for i, predicate in ipairs(slots) do
            if not filled[i] and predicate(content) then
                filled[i] = content
                break
            end
        end
        return filled
    end
end

---@param opts Portal.SearchOptions
---@return fun(r: Portal.Result): Portal.ExtendedResult
local function extend_result(opts)
    return function(result)
        return {
            result = result,
            opts = opts,
        }
    end
end

---@param generator Portal.Generator
---@param transformer? Portal.Transformer
---@return Portal.Query
function Query.new(generator, transformer)
    return setmetatable({
        generator = generator,
        transformer = transformer,
        opts = nil,
    }, Query)
end

---@param opts? Portal.SearchOptions
---@return Portal.Query
function Query:prepare(opts)
    self.opts = vim.tbl_deep_extend("force", self.opts or {}, opts or {})
    return self
end

---@return table
function Query:search()
    local results, defaults = self.generator()

    local iter = Iter.iter(results)

    defaults = defaults or {}

    -- We don't want the default filter to be applied twice. Store it here and
    -- clear it from the defaults table so that it doesn't get added to the opts
    local default_filter = defaults.filter
    defaults.filter = nil

    local opts = vim.tbl_deep_extend("keep", self.opts or {}, defaults)

    if opts.start then
        -- Assumption: iterator must be a double-ended (ListIter) to reverse
        if opts.reverse then
            opts.start = iter:len() - (opts.start - 1)

            -- Clamp the starting position to the end of the results
            opts.start = math.min(iter:len(), opts.start)
        end

        -- Clamp the starting position to the beginning of the results
        opts.start = math.max(1, opts.start)
    end

    -- Prepare iterator

    if opts.reverse then
        iter:rev()
    end

    if opts.lookback then
        iter:take(opts.lookback)
    end

    if opts.start then
        iter:skip(opts.start - 1)
    end

    if opts.skip then
        iter:skip(opts.skip)
    end

    if default_filter then
        iter:filter(default_filter)
    end

    if self.transformer then
        -- stylua: ignore
        iter:map(extend_result(opts))
            :enumerate()
            :map(self.transformer)
    end

    if opts.filter then
        iter:filter(opts.filter)
    end

    if opts.slots then
        return iter:fold({}, match_slots(opts.slots))
    elseif opts.limit then
        return iter:take(opts.limit):totable()
    else
        return iter:totable()
    end
end

return Query
