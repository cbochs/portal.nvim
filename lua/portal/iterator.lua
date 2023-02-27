---@class Portal.Iterator
---@field iterable table
local Iterator = {}

---@class Portal.Predicate
---@field name? string
---@field call fun(value: any): boolean

---@alias Portal.SearchQuery Portal.Predicate | Portal.Predicate[]

---@class Portal.SearchResult
---@field value any
---@field predicate Portal.Predicate

---@generic T
---@param iterable? T[]
---@return Portal.Iterator
function Iterator:new(iterable)
    local iterator = { iterable = iterable or {} }
    setmetatable(iterator, self)
    self.__index = self
    return iterator
end

---@param index? number
function Iterator:next(index)
    index = (index or 0) + 1
    local value = self.iterable[index]
    if value then
        return index, value
    end
end

---@param index? number
function Iterator:iter(index)
    return self.next, self, (index or 0)
end

---@class Portal.FilterAdapter
---@field iterator Portal.Iterator
---@field predicate Portal.Predicate
local Filter = Iterator:new()

---@param iterator Portal.Iterator
---@param predicate Portal.Predicate
---@return Portal.Iterator
function Filter:new(iterator, predicate)
    local filter = {
        iterator = iterator,
        predicate = predicate,
    }
    setmetatable(filter, self)
    self.__index = self
    return filter
end

---@param index? number
---@return any
function Filter:next(index)
    while true do
        local new_index, value = self.iterator:next(index)
        index = new_index
        if index == nil then
            break
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

---@param iterator Portal.Iterator
---@param n number
---@return Portal.Iterator
function Take:new(iterator, n)
    if n < 0 then
        error("Take 'n' must be a positive number.")
    end

    local take = { iterator = iterator, n = n }
    setmetatable(take, self)
    self.__index = self
    return take
end

---@param index? number
---@return any
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

---@param iterator Portal.Iterator
---@param f fun(value: any): any
---@return Portal.Iterator
function Map:new(iterator, f)
    local map = { iterator = iterator, f = f }
    setmetatable(map, self)
    self.__index = self
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
    self.__index = self
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
                local result = { value = value, predicate = predicate }
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

---@generic T
---@return T[]
function Iterator:collect()
    local values = {}
    for _, value in self:iter() do
        table.insert(values, value)
    end
    return values
end

return Iterator
