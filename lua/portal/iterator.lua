local log = require("portal.log")

---@class Portal.Iterator
---@field iterable table
---@field step integer
---@field start_index integer
---@field explicit_start boolean
local Iterator = {}
Iterator.__index = Iterator

---@alias Portal.Predicate fun(value: any):boolean

---@param iterable? table
---@return Portal.Iterator
function Iterator:new(iterable)
    local iterator = {
        iterable = iterable or {},
        step = 1,
        start_index = 1,
        explicit_start = false,
    }
    setmetatable(iterator, self)
    return iterator
end

---@param index? integer
function Iterator:next(index)
    if not index then
        index = self.start_index - self.step
    end
    index = index + self.step

    local value = self.iterable[index]
    if value then
        return index, value
    end
end

function Iterator:iter()
    return self.next, self, nil
end

---@generic T
---@return T[]
function Iterator:collect()
    local values = {}
    for _, value in self:iter() do
        table.insert(values, value)
    end
    return values
end

---@return table
function Iterator:collect_table()
    local values = {}
    for _, value in self:iter() do
        values[value[1]] = value[2]
    end
    return values
end

---@param reducer fun(acc: any, val: any, i?: integer): any
---@param initial_state any
---@return any
function Iterator:reduce(reducer, initial_state)
    local values = initial_state
    for i, value in self:iter() do
        values = reducer(values, value, i)
    end
    return values
end

function Iterator:flatten()
    local values = {}
    for _, value in self:iter() do
        vim.list_extend(values, value)
    end
    return values
end

---@param start_iter Portal.Iterator
---@return Portal.Iterator
local function root_iter(start_iter)
    local current_iter = start_iter
    while true do
        if not current_iter.iterator then
            if current_iter.iterable then
                return current_iter
            else
                log.error("At root iterator, but could not find iterable.")
            end
        end
        current_iter = current_iter.iterator
    end
end

---@param n integer
---@return Portal.Iterator
function Iterator:start_at(n)
    if n == nil then
        log.error("Iterator.start_at: start index cannot be nil.")
    end
    local iter = root_iter(self)
    iter.start_index = n
    iter.explicit_start = true
    return self
end

---@return Portal.Iterator
function Iterator:reverse()
    local iter = root_iter(self)
    iter.step = -iter.step

    -- Only change the start index if it is the default
    if not iter.explicit_start then
        if iter.start_index == 1 then
            iter.start_index = #iter.iterable
        else
            iter.start_index = 1
        end
    end

    return self
end

---@class Portal.RepeatAdapter
---@field value any
local Repeat = Iterator:new()
Repeat.__index = Repeat

function Repeat:new(value)
    local rrepeat = { value = value }
    setmetatable(rrepeat, self)
    return rrepeat
end

function Repeat:next(index)
    return (index or 0) + 1, vim.deepcopy(self.value)
end

-- luacheck: ignore
function Iterator:rrepeat(value)
    return Repeat:new(value)
end

---@class Portal.SkipAdapter
---@field iterator Portal.Iterator
---@field n integer
local Skip = Iterator:new()
Skip.__index = Skip

function Skip:new(iterator, n)
    if n == nil then
        log.error("Iterator.skip: skipped items 'n' cannot be nil.")
    end
    if n < 0 then
        log.error("Iterator.skip: 'n' must be a non-negative integer.")
    end

    local skip = {
        iterator = iterator,
        n = n,
    }
    setmetatable(skip, self)
    return skip
end

function Skip:next(index)
    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            return nil, nil
        end
        if self.n == 0 then
            return index, value
        end
        self.n = self.n - 1
    end
end

function Iterator:skip(n)
    return Skip:new(self, n)
end

---@class Portal.StepByAdapter
---@field iterator Portal.Iterator
---@field n integer
local StepBy = Iterator:new()
StepBy.__index = StepBy

function StepBy:new(iterator, n)
    if n == nil then
        log.error("Iterator.step_by: step size 'n' cannot be nil.")
    end
    if n <= 0 then
        log.error("Iterator.step_by: 'n' must be a positive integer.")
    end

    local step_by = {
        iterator = iterator,
        n = n,
        count = -1,
    }
    setmetatable(step_by, self)
    return step_by
end

function StepBy:next(index)
    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            return nil, nil
        end
        self.count = (self.count + 1) % self.n
        if self.count == 0 then
            return index, value
        end
    end
end

---@param n integer
---@return Portal.Iterator
function Iterator:step_by(n)
    return StepBy:new(self, n)
end

---@class Portal.FilterAdapter
---@field iterator Portal.Iterator
---@field predicate Portal.Predicate
local Filter = Iterator:new()
Filter.__index = Filter

---@param iterator Portal.Iterator
---@param predicate Portal.Predicate
---@return Portal.Iterator
function Filter:new(iterator, predicate)
    if predicate == nil then
        log.error("Iterator.filter: predicate function cannot be nil.")
    end

    local filter = {
        iterator = iterator,
        predicate = predicate,
    }
    setmetatable(filter, self)
    return filter
end

---@param index? integer
function Filter:next(index)
    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            return nil, nil
        end
        if self.predicate(value) then
            return index, value
        end
    end
end

---@param predicate Portal.Predicate
---@return Portal.Iterator
function Iterator:filter(predicate)
    return Filter:new(self, predicate)
end

---@class Portal.TakeAdapter
---@field iterator Portal.Iterator
---@field n integer
local Take = Iterator:new()
Take.__index = Take

---@param iterator Portal.Iterator
---@param n integer
---@return Portal.Iterator
function Take:new(iterator, n)
    if n == nil then
        log.error("Iterator.take: predicate function cannot be nil.")
    end
    if n < 0 then
        log.error("Iterator.take: 'n' must be a non-negative integer.")
    end

    local take = {
        iterator = iterator,
        n = n,
    }
    setmetatable(take, self)
    return take
end

---@param index? integer
function Take:next(index)
    if self.n == 0 then
        return nil, nil
    end

    self.n = self.n - 1

    local new_index, value = self.iterator:next(index)
    index = new_index
    if index ~= nil then
        return index, value
    end
end

---@param n? integer
---@return Portal.Iterator
function Iterator:take(n)
    return Take:new(self, n or 1)
end

---@class Portal.MapAdapter
---@field iterator Portal.Iterator
---@field f fun(v: any, i: integer): any
local Map = Iterator:new()
Map.__index = Map

---@param iterator Portal.Iterator
---@param f fun(value: any): any
---@return Portal.Iterator
function Map:new(iterator, f)
    if f == nil then
        log.error("Iterator.map: map function cannot be nil.")
    end

    local map = {
        iterator = iterator,
        f = f,
    }
    setmetatable(map, self)
    return map
end

---@param index? any
function Map:next(index)
    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            return nil, nil
        end

        local mapped_value = self.f(value, index)
        if mapped_value then
            return index, mapped_value
        end
    end
end

---@param f fun(value: any): any
---@return Portal.Iterator
function Iterator:map(f)
    return Map:new(self, f)
end

return Iterator
