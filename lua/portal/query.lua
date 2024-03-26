local Iter = require("portal.iterator")

---@alias Portal.Generator fun(...): Portal.Iter, Portal.QueryOptions? | Portal.ExtendedGenerator

---@class Portal.ExtendedGenerator
---@field generate fun(...): Portal.Iter, Portal.QueryOptions?
---@field transform fun(i: integer, r: Portal.Result): Portal.Content

---@class Portal.Query
---@field generator Portal.ExtendedGenerator
---@field opts? Portal.QueryOptions
local Query = {}
Query.__index = Query

---@class Portal.QueryOptions
---@field start? integer the absolute starting position
---@field skip? integer
---@field reverse? boolean
---@field lookback? integer maximum number of searched items
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

---@param _ integer
---@param extended_result Portal.ExtendedResult
---@return Portal.Result
local function unextend_result(_, extended_result)
    return extended_result.result
end

local function passthrough()
    return true
end

---@param generator Portal.Generator
---@return Portal.Query
function Query.new(generator)
    ---@diagnostic disable-next-line: cast-local-type
    generator = type(generator) == "table" and generator
        or {
            generate = generator,
            transform = unextend_result,
        }

    return setmetatable({
        generator = generator,
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
    local iter, defaults = self.generator.generate()

    defaults = vim.tbl_deep_extend("keep", defaults or {}, {
        start = 1,
        skip = 0,
        reverse = false,
        filter = passthrough,
    })

    local opts = vim.tbl_deep_extend("keep", self.opts or {}, defaults or {})

    -- Assume: iterator must be a double-ended (ListIter) to reverse
    if opts.reverse then
        opts.start = iter:len() - opts.start

        -- Clamp the starting position to the end of the results
        opts.start = math.min(iter:len(), opts.start)
    end

    -- Clamp the starting position to the beginning of the results
    opts.start = math.max(1, opts.start)

    if opts.reverse then
        iter:rev()
    end

    if opts.lookback then
        iter:take(opts.lookback)
    end

    -- Prepare iterator
    iter:skip(opts.start - 1)
        :skip(opts.skip)
        :map(extend_result(opts))
        :enumerate()
        :map(self.generator.transform)
        :filter(defaults.filter)
        :filter(opts.filter)

    return iter
end

return Query
