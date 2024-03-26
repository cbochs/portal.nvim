---@brief
---
---[vim.iter()]() does not exist in Neovim < 0.10. This module moves away from
---Portal's original iterator module to a (temporary) reimplementation of
---vim.iter. When Neovim 0.10 is released this module should be deleted and
---replaced with vim.iter. Until then, this will suffice.

---@class Portal.Iter
---@field _table table
---@field _head number
---@field _tail number
local ListIter = {}
ListIter.__index = ListIter
ListIter.__call = function(self)
    return self:next()
end

--- Packed tables use this as their metatable
local packedmt = {}

local function unpack(t)
    if type(t) == "table" and getmetatable(t) == packedmt then
        return _G.unpack(t, 1, t.n)
    end
    return t
end

local function pack(...)
    local n = select("#", ...)
    if n > 1 then
        return setmetatable({ n = n, ... }, packedmt)
    end
    return ...
end

local function sanitize(t)
    if type(t) == "table" and getmetatable(t) == packedmt then
        -- Remove length tag
        t.n = nil
    end
    return t
end

---@return Portal.Iter
function ListIter.new(tbl)
    return setmetatable({
        _table = tbl,
        _head = 1,
        _tail = #tbl + 1,
    }, ListIter)
end

---@return Portal.Iter
function ListIter.iter(tbl)
    return ListIter.new(tbl)
end

---@return any
function ListIter:next()
    if self._head ~= self._tail then
        local inc = self._head < self._tail and 1 or -1
        local val = self._table[self._head]

        self._head = self._head + inc

        return unpack(val)
    end
end

---@return integer
function ListIter:len()
    return self._tail - self._head
end

---@param fn fun(...): ...
---@return Portal.Iter
function ListIter:map(fn)
    local inc = self._head < self._tail and 1 or -1
    local num = self._head

    for i = self._head, self._tail - inc, inc do
        local val = pack(fn(unpack(self._table[i])))
        if val ~= nil then
            self._table[num] = val
            num = num + inc
        end
    end

    self._tail = num
    return self
end

---@param fn fun(...): boolean
---@return Portal.Iter
function ListIter:filter(fn)
    local inc = self._head < self._tail and 1 or -1
    local num = self._head

    for i = self._head, self._tail - inc, inc do
        local val = self._table[i]
        if fn(unpack(val)) then
            self._table[num] = val
            num = num + inc
        end
    end

    self._tail = num
    return self
end

---@generic T
---
---@param init T
---@param fn fun(acc: T, ...): T
---@return T
function ListIter:fold(init, fn)
    local acc = init
    local inc = self._head < self._tail and 1 or -1
    for i = self._head, self._tail - inc, inc do
        acc = fn(acc, unpack(self._table[i]))
    end
    return acc
end

---@return Portal.Iter
function ListIter:rev()
    local inc = self._head < self._tail and 1 or -1
    self._head, self._tail = self._tail - inc, self._head - inc
    return self
end

---@param n number
---@return Portal.Iter
function ListIter:take(n)
    local inc = self._head < self._tail and 1 or -1
    local cmp = self._head < self._tail and math.min or math.max
    self._tail = cmp(self._tail, self._head + n * inc)
    return self
end

---@param n number
---@return Portal.Iter
function ListIter:skip(n)
    local inc = self._head < self._tail and n or -n
    local cmp = self._head < self._tail and math.min or math.max
    self._head = cmp(self._tail, self._head + inc)
    return self
end

---@return Portal.Iter
function ListIter:enumerate()
    local i = 0
    local function enumerate(...)
        i = i + 1
        return i, ...
    end
    return self:map(enumerate)
end

---@return any
function ListIter:peek()
    if self._head ~= self._tail then
        return self._table[self._head]
    end
end

---@param v table
---@param max_depth number
---@param depth number
---@param result table
---@return table|nil flattened
local function flatten(v, max_depth, depth, result)
    if depth < max_depth and type(v) == "table" then
        local i = 0
        for _ in pairs(v) do
            i = i + 1

            if v[i] == nil then
                -- short-circuit: this is not a list like table
                return nil
            end

            if flatten(v[i], max_depth, depth + 1, result) == nil then
                return nil
            end
        end
    else
        result[#result + 1] = v
    end

    return result
end

---@param depth? number
---@return Portal.Iter
function ListIter:flatten(depth)
    depth = depth or 1

    local inc = self._head < self._tail and 1 or -1
    local target = {}

    for i = self._head, self._tail - inc, inc do
        local flattened = flatten(self._table[i], depth, 0, {})

        -- exit early if we try to flatten a dict-like table
        if flattened == nil then
            error("flatten() requires a list-like table")
        end

        for _, v in pairs(flattened) do
            target[#target + 1] = v
        end
    end

    self._head = 1
    self._tail = #target + 1
    self._table = target

    return self
end

local function totable(iter)
    local t = {}

    while true do
        local args = pack(iter:next())
        if args == nil then
            break
        end

        t[#t + 1] = sanitize(args)
    end
    return t
end

---@return table
function ListIter:totable()
    if self._head >= self._tail then
        return totable(self)
    end

    local needs_sanitize = getmetatable(self._table[1]) == packedmt

    -- Reindex and sanitize.
    local len = self._tail - self._head

    if needs_sanitize then
        for i = 1, len do
            self._table[i] = sanitize(self._table[self._head - 1 + i])
        end
    else
        for i = 1, len do
            self._table[i] = self._table[self._head - 1 + i]
        end
    end

    for i = len + 1, table.maxn(self._table) do
        self._table[i] = nil
    end

    self._head = 1
    self._tail = len + 1

    return self._table
end

return ListIter
