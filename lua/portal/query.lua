---@class Portal.Query
---@field generator Portal.Generator
---@field opts? Portal.QueryOptions
local Query = {}
Query.__index = Query

---@param opts? Portal.QueryOptions
---@param generator Portal.Generator
---@return Portal.Query
function Query.new(generator, opts)
    return setmetatable({
        generator = generator,
        opts = opts,
    }, Query)
end

---@param opts? Portal.QueryOptions
---@return Portal.Query
function Query:prepare(opts)
    self.opts = opts
    return self
end

---@param slots? Portal.Slots
---@param opts? Portal.QueryOptions
---@return table
function Query:search(slots, opts)
    opts = vim.tbl_deep_extend("force", self.opts or {}, opts or {})

    local iter = self.generator(opts)

    if not slots then
        return iter:totable()
    elseif type(slots) == "number" then
        ---@cast slots integer
        return iter:take(slots):totable()
    else
        if type(slots) == "function" then
            slots = { slots }
        end

        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast slots Portal.Predicate[]

        ---@param filled table<integer, Portal.Content>
        ---@param content Portal.Content
        ---@return table<integer, Portal.Content>
        local function match_slots(filled, content)
            for i, predicate in ipairs(slots) do
                if not filled[i] and predicate(content) then
                    filled[i] = content
                    break
                end
            end
            return filled
        end

        return iter:fold({}, match_slots)
    end
end

return Query
