local Iter = require("portal.iterator")

---@alias Portal.Generator fun(...): Portal.Iter, Portal.QueryOptions? | Portal.ExtendedGenerator

---@class Portal.ExtendedGenerator
---@field generate fun(...): Portal.Iter, Portal.QueryOptions?
---@field transform fun(i: integer, r: Portal.Result): Portal.Content

---@class Portal.Query
---@field generator Portal.Generator
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

local function passthrough()
    return true
end

---@param generator Portal.Generator
---@return Portal.Query
function Query.new(generator)
    return setmetatable({
        generator = generator,
        opts = nil,
    }, Query)
end

function Query:is_extended()
    return type(self.generator) == "table"
end

---@param opts? Portal.QueryOptions
---@return Portal.Query
function Query:prepare(opts)
    self.opts = vim.tbl_deep_extend("force", self.opts or {}, opts or {})
    return self
end

---@return Portal.Iter
function Query:search()
    local iter, defaults
    if self:is_extended() then
        iter, defaults = self.generator.generate()
    else
        iter, defaults = self.generator()
    end

    defaults = defaults or {}

    -- We don't want the default filter to be applied twice. Store it here and
    -- clear it from the defaults table so that it doesn't get added to the opts
    local default_filter = defaults.filter
    defaults.filter = nil

    defaults = vim.tbl_deep_extend("keep", defaults or {}, {
        start = 1,
        skip = 0,
        reverse = false,
    })

    local opts = vim.tbl_deep_extend("keep", self.opts or {}, defaults)

    -- Assume: iterator must be a double-ended (ListIter) to reverse
    if opts.reverse then
        opts.start = iter:len() - opts.start

        -- Clamp the starting position to the end of the results
        opts.start = math.min(iter:len(), opts.start)
    end

    -- Clamp the starting position to the beginning of the results
    opts.start = math.max(1, opts.start)

    -- Prepare iterator

    if opts.reverse then
        iter:rev()
    end

    if opts.lookback then
        iter:take(opts.lookback)
    end

    -- stylua: ignore
    iter:skip(opts.start - 1)
        :skip(opts.skip)

    if self:is_extended() then
        -- stylua: ignore
        iter:map(extend_result(opts))
            :enumerate()
            :map(self.generator.transform)
    end

    if default_filter then
        iter:filter(defaults.filter)
    end

    if opts.filter then
        iter:filter(opts.filter)
    end

    if opts.limit then
        iter:take(opts.limi)
    end

    return iter
end

return Query
