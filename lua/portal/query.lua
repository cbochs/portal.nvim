local Iter = require("portal.iterator")

---@class Portal.Query
---@field generator Portal.Generator
---@field transformer Portal.Transformer
---@field opts? Portal.QueryOptions
local Query = {}
Query.__index = Query

---@class Portal.QueryOptions
---@field start? integer the absolute starting position
---@field skip? integer
---@field reverse? boolean
---@field lookback? integer maximum number of searched items
---@field limit? integer maximum number of returned results
---@field filter? Portal.Predicate

---@alias Portal.Iterable table | function | Portal.Iter
---@alias Portal.Predicate fun(...): boolean
---@alias Portal.Generator fun(): Portal.Iterable, Portal.QueryOptions?
---@alias Portal.Transformer fun(i: integer, r: Portal.ExtendedResult): Portal.Content?
---@alias Portal.Result any

---@class Portal.ExtendedResult
---@field result Portal.Result
---@field opts Portal.QueryOptions

---@class Portal.Content
---@field type? string
---@field buffer? integer
---@field path? string
---@field cursor? integer[] (1, 0)-indexed cursor position
---@field select? fun(c: Portal.Content)
---@field extra? table

---@param opts Portal.QueryOptions
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

---@param opts? Portal.QueryOptions
---@return Portal.Query
function Query:prepare(opts)
    self.opts = vim.tbl_deep_extend("force", self.opts or {}, opts or {})
    return self
end

---@return Portal.Iter
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

    if opts.limit then
        iter:take(opts.limit)
    end

    return iter
end

return Query
