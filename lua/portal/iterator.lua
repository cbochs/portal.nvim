---@class Portal.Iterator
---@field iterable table
---@field step_size number
---@field start_index number
local Iterator = {}

---@class Portal.Predicate
---@field name? string
---@field call fun(value: any): boolean

---@alias Portal.SearchQuery Portal.Predicate | Portal.Predicate[]

---@class Portal.SearchResult
---@field value any
---@field predicate Portal.Predicate

---@param iterable? table
---@return Portal.Iterator
function Iterator:new(iterable)
    local iterator = {
        iterable = iterable or {},
        step_size = 1,
        start_index = 1,
    }
    setmetatable(iterator, self)
    self.__index = self
    return iterator
end

---@param index? number
function Iterator:next(index)
    if not index then
        index = self.start_index - self.step_size
    end
    index = index + self.step_size

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
---@param index? number
---@return T[]
function Iterator:collect(index)
    local values = {}
    for _, value in self:iter(index) do
        table.insert(values, value)
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

function Iterator:start_at(n)
    root_iter(self).start_index = n
    return self
end

---@return Portal.Iterator
function Iterator:reverse()
    local iter = root_iter(self)
    iter.step_size = -1

    -- Only change the start index if it is the default
    if iter.start_index == 1 then
        iter.start_index = #iter.iterable
    end

    return self
end

local StepBy = Iterator:new()
StepBy.__index = StepBy

function StepBy:new(iterator, n)
    if n < 0 then
        require("portal.log").error("StepBy 'n' must be a positive number.")
        error("StepBy 'n' must be a positive number.")
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
    if n < 0 then
        require("portal.log").error("Take 'n' must be a positive number.")
        error("Take 'n' must be a positive number.")
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

---@param n number
---@return Portal.Iterator
function Iterator:take(n)
    return Take:new(self, n)
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

---@class Portal.SearchAdapter
---@field iterator Portal.Iterator
---@field query Portal.SearchQuery
---@field query_results Portal.SearchQuery
local Search = Iterator:new()
Search.__index = Search

---@param iterator Portal.Iterator
---@param query Portal.SearchQuery
---@return Portal.Iterator
function Search:new(iterator, query)
    local search = {
        iterator = iterator,
        query = query,
        query_results = {},
    }
    setmetatable(search, self)
    return search
end

---@param index? number
function Search:next(index)
    if #self.query_results == #self.query then
        return nil, nil
    end

    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            break
        end

        for i, predicate in ipairs(self.query) do
            if self.query_results[i] == nil and predicate.call(value) then
                local result = { value = value, index = i, predicate = predicate }
                self.query_results[i] = result
                return index, result
            end
        end
    end
end

---@param query Portal.SearchQuery[]
---@return Portal.Iterator
function Iterator:search(query)
    return Search:new(self, query)
end

return Iterator
