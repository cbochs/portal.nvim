local config = require("portal.config")
local deprecated = require("portal.deprecated")

local M = {}

function M.tag()
    deprecated(
        'tag.tag has been deprecated in favour of grapple.nvim integration. Please use require("grapple").tag instead.'
    )
    if config.integrations.grapple then
        require("grapple").tag()
    end
end

function M.untag()
    deprecated(
        'tag.untag has been deprecated in favour of grapple.nvim integration. Please use require("grapple").untag instead.'
    )
    if config.integrations.grapple then
        require("grapple").untag()
    end
end

function M.toggle()
    deprecated(
        'tag.toggle has been deprecated in favour of grapple.nvim integration. Please use require("grapple").toggle instead.'
    )
    if config.integrations.grapple then
        require("grapple").toggle()
    end
end

--- @param buffer? integer
function M.exists(buffer)
    deprecated(
        'tag.exists has been deprecated in favour of grapple.nvim integration. Please use require("grapple").exists instead.'
    )
    if config.integrations.grapple then
        return require("grapple").exists({ buffer = (buffer or 0) })
    end
end

function M.reset()
    deprecated(
        'tag.reset has been deprecated in favour of grapple.nvim integration. Please use require("grapple").reset instead.'
    )
    if config.integrations.grapple then
        require("grapple").reset()
    end
end

return M
