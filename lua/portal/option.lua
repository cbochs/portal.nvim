local Option = {}

function Option:new(value)
    local option = { value = value }
    setmetatable(option, self)
    self.__index = self
    return option
end

function Option:is_some()
    return self.value ~= nil
end

function Option:is_none()
    return not self:is_some()
end

function Option:unwrap()
    if self:is_none() then
        error("Cannot unwrap None-type")
    end
    return self.value
end

function Option:unwrap_or(default_value)
    return self:is_some() and self.value or default_value
end

return Option
