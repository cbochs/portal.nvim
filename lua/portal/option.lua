---@class Portal.Option
---@field value any
local Option = {}

---@param value any
---@return Portal.Option
function Option:new(value)
    local option = { value = value }

    setmetatable(option, self)
    self.__index = self

    return option
end

local NONE = Option:new()

-- luacheck: ignore
function Option:none()
    return NONE
end

-- luacheck: ignore
function Option:some(value)
    return Option:new(value)
end

function Option:is_some()
    return self.value ~= nil
end

function Option:is_none()
    return not self:is_some()
end

---@return any
function Option:unwrap()
    if self:is_none() then
        error("Cannot unwrap None-type.")
        require("portal.log").error("Cannot unwrap None-type.")
    end
    return self.value
end

---@param default_value any
---@return any
function Option:unwrap_or(default_value)
    return self:is_some() and self.value or default_value
end

return Option
