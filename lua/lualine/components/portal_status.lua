return function()
	local highlight = require("portal.highlight")
	local mark = require("portal.mark")
	if mark.exists() then
		return "%#" .. highlight.groups.leap_mark_active .. "#" .. "[M]" .. "%*"
	else
		return "%#" .. highlight.groups.leap_mark_inactive .. "#" .. "[U]" .. "%*"
	end
end
