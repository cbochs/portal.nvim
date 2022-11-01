local config = require("portal.config")
local state = require("portal.state")
local types = require("portal.types")

local M = {}

local tags = {}

function M.tag()
	local buffer_name = vim.api.nvim_buf_get_name(0)
	tags[buffer_name] = true
end

function M.untag()
	local buffer_name = vim.api.nvim_buf_get_name(0)
	tags[buffer_name] = nil
end

function M.toggle()
	if M.exists() then
		M.untag()
	else
		M.tag()
	end
end

--- @param buffer? integer
function M.exists(buffer)
	local buffer_name = vim.api.nvim_buf_get_name(buffer or 0)
	return tags[buffer_name] or false
end

function M.reset()
	tags = {}
end

function M.load(save_path)
	if state.file_exists(save_path) then
		tags = state.load(save_path)
	end

	if config.tag.scope ~= types.Scope.NONE then
		vim.api.nvim_create_augroup("PortalSave", { clear = true })
		vim.api.nvim_create_autocmd({ "VimLeave" }, {
			group = "PortalSave",
			callback = function()
				require("portal.tag").save(config.tag.save_path)
			end,
		})
	end
end

function M.save(save_path)
	if config.tag.scope == types.Scope.NONE then
		return
	end
	state.save(save_path, tags)
end

return M
