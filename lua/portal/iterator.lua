---@class Portal.Iterator
---@field iterable table
---@field step number
---@field start_index number
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
    }
    setmetatable(iterator, self)
    return iterator
end

---@param index? number
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

---@param index? number
function Iterator:iter(index)
    return self.next, self, index
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

---@param reducer fun(acc: any, val: any, i?: number): any
---@param initial_state any
---@return any
function Iterator:reduce(reducer, initial_state)
    local values = initial_state
    for i, value in self:iter() do
        values = reducer(values, value, i)
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
                error("At root iterator, but could not find iterable.")
            end
        end
        current_iter = current_iter.iterator
    end
end

---@param n? number
---@return Portal.Iterator
function Iterator:start_at(n)
    if n == nil then
        error("Iterator.start_at: start index cannot be nil.")
    end
    root_iter(self).start_index = n
    return self
end

---@return Portal.Iterator
function Iterator:reverse()
    local iter = root_iter(self)
    iter.step = -1

    -- Only change the start index if it is the default
    if iter.start_index == 1 then
        iter.start_index = #iter.iterable
    end

    return self
end

local StepBy = Iterator:new()
StepBy.__index = StepBy

function StepBy:new(iterator, n)
    if n == nil then
        error("Iterator.step_by: step amount cannot be nil.")
    end
    if n <= 0 then
        error("Iterator.step_by: 'n' must be a positive number.")
    end

    local step_by = {
        iterator = iterator,
        n = n,
        count = n - 1,
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

---@param n number
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
        error("Iterator.filter: predicate function cannot be nil.")
    end

    local filter = {
        iterator = iterator,
        predicate = predicate,
    }
    setmetatable(filter, self)
    return filter
end

---@param index? number
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
---@field n number
local Take = Iterator:new()
Take.__index = Take

---@param iterator Portal.Iterator
---@param n number
---@return Portal.Iterator
function Take:new(iterator, n)
    if n == nil then
        error("Iterator.take: predicate function cannot be nil.")
    end
    if n < 0 then
        error("Iterator.take: 'n' must be a positive number.")
    end

    local take = {
        iterator = iterator,
        n = n,
    }
    setmetatable(take, self)
    return take
end

---@param index? number
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

---@param n? number
---@return Portal.Iterator
function Iterator:take(n)
    return Take:new(self, n or 1)
end

---@class Portal.MapAdapter
---@field iterator Portal.Iterator
---@field f fun(value: any): any
local Map = Iterator:new()
Map.__index = Map

---@param iterator Portal.Iterator
---@param f fun(value: any): any
---@return Portal.Iterator
function Map:new(iterator, f)
    if f == nil then
        error("Iterator.map: map function cannot be nil.")
    end

    local map = {
        iterator = iterator,
        f = f,
    }
    setmetatable(map, self)
    return map
end

---@param index? any
---@return any
function Map:next(index)
    local new_index, value = self.iterator:next(index)
    index = new_index
    if index ~= nil then
        return index, self.f(value)
    end
end

---@param f fun(value: any): any
---@return Portal.Iterator
function Iterator:map(f)
    return Map:new(self, f)
end

return Iterator
