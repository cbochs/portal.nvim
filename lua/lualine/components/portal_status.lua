return function()
    local highlight = require("portal.highlight")
    local tag = require("portal.tag")
    if tag.exists() then
        return "%#" .. highlight.groups.leap_tag_active .. "#" .. "[M]" .. "%*"
    else
        return "%#" .. highlight.groups.leap_tag_inactive .. "#" .. "[U]" .. "%*"
    end
end
