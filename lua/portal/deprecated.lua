local M = {}

local log = require("portal.log").new({
	use_console = true,
	use_file = false,
	level = "warn",
}, false)

setmetatable(M, {
	__call = function(_, ...)
		if log == nil then
			return
		end
		log.warn(...)
	end,
})

return M
