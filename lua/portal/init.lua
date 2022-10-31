local config = require("portal.config")
local input = require("portal.input")
local jump = require("portal.jump")
local mark = require("portal.mark")
local query = require("portal.query")
local types = require("portal.types")

local M = {}

--- @type Portal.Namespace
local _ns = vim.api.nvim_create_namespace("PortalNamespace")

--- @class Portal.Previewer
--- @field label Portal.Labeller
--- @field open Portal.Opener
--- @field close Portal.Closer

--- @alias Portal.Labeller fun(jumps: Portal.Jump[], namespace: Portal.Namespace): Portal.Label[]
--- @alias Portal.Opener fun(jumps: Portal.Jump[], labels: string[], namespace: Portal.Namespace): Portal.Portal[]
--- @alias Portal.Closer fun(portals: Portal.Portal[])

--- @alias Portal.Label string
--- @alias Portal.Namespace integer

--- @class Portal.Portal
--- @field jump Portal.Jump
--- @field label string
--- @field windows integer[]
--- @field namespace integer

--- @class Portal.Options
--- @field query Portal.QueryLike[]
--- @field previewer Portal.Previewer
--- @field namespace Portal.Namespace

--- @param opts? Portal.Config
function M.setup(opts)
	config.load(opts or {})
	mark.load(config.mark.save_path)
end

--- @param direction Portal.Direction
--- @param opts? Portal.Options
function M.jump(direction, opts)
	opts = opts or {}

	local queries = query.resolve(opts.query or config.jump.query)
	local jumps = jump.search(queries, direction)

	local previewer = opts.previewer or require("portal.previewer")
	local namespace = opts.namespace or _ns
	local portals = M.open(jumps, previewer, namespace)

	M.select(portals)
	M.close(portals, previewer)
end

--- @param opts? Portal.Options
function M.jump_backward(opts)
	M.jump(types.Direction.BACKWARD, opts)
end

--- @param opts? Portal.Options
function M.jump_forward(opts)
	M.jump(types.Direction.FORWARD, opts)
end

--- @param jumps Portal.Jump[]
--- @param previewer Portal.Previewer
--- @param namespace? integer
--- @return Portal.Portal[]
function M.open(jumps, previewer, namespace)
	namespace = namespace or _ns

	local labels = previewer.label(jumps, namespace)
	local portals = previewer.open(jumps, labels, namespace)

	-- Force UI to redraw to avoid user input blocking preview windows from
	-- showing up.
	vim.cmd("redraw")

	return portals
end

--- @param portals Portal.Portal[]
function M.select(portals)
	while true do
		local input_label = input.get_label()
		if input_label == nil then
			break
		end

		for _, portal in pairs(portals) do
			if portal.jump.direction == types.Direction.NONE then
				goto continue
			end
			if input_label == portal.label then
				jump.select(portal.jump)
				goto exit
			end
			::continue::
		end
	end
	::exit::
end

--- @param portals Portal.Portal[]
--- @param previewer Portal.Previewer
function M.close(portals, previewer)
	previewer.close(portals)
end

return M
