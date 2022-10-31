local config = require("portal.config")
local types = require("portal.types")

local M = {}

--- @class Portal.Jump
--- @field buffer integer
--- @field direction Portal.Direction
--- @field distance integer
--- @field row integer
--- @field col integer
--- @field query Portal.Query

--- @return Portal.Jump
local function default()
	return {
		buffer = -1,
		direction = types.Direction.NONE,
		distance = 0,
		row = 0,
		col = 0,
	}
end

--- @param direction Portal.Direction
--- @return fun(): Portal.Jump
local function jumplist_iter(direction)
	local jumplist_tuple = vim.fn.getjumplist()

	local vim_jumplist = jumplist_tuple[1]
	local start_pos = jumplist_tuple[2] + 1

	local signed_step = 1
	if direction == types.Direction.BACKWARD then
		signed_step = -1
	elseif direction == types.Direction.FORWARD then
		signed_step = 1
	end

	local displacement = 0
	local current_pos = start_pos + displacement
	local max_lookback = #vim_jumplist

	return function()
		displacement = displacement + signed_step
		current_pos = start_pos + displacement

		if current_pos < 1 or current_pos > #vim_jumplist then
			return
		end
		if displacement > max_lookback then
			return
		end

		local vim_jump = vim_jumplist[current_pos]

		--- @type Portal.Jump
		local jump = {
			buffer = vim_jump.bufnr,
			distance = math.abs(displacement),
			direction = direction,
			row = vim_jump.lnum,
			col = vim_jump.col,
		}

		return jump
	end
end

--- Populate an ordered list of available jumps based on an input list of
--- queries.
---
--- In order to generate unique jumps, an individual jump may only be
--- associated with a unique query _predicate_ once. However, a jump may be
--- associated with more than one query.
---
--- Example:
---
--- Given an list of jump queries: `{ "valid", "valid", "marked" }`,
--- the resulting ordered list will be:
--- * the first jump will be associated with the first item in the jumplist
--- * the second jump will be associated with the second item in the jumplist
--- * if the first jump was also `marked`, the third jump will also be
---   associated with the first item in the jumplist
---
--- @param queries Portal.Query[]
--- @param direction Portal.Direction
--- @return Portal.Jump[]
function M.search(queries, direction)
	--- @type Portal.Jump[]
	local identified_jumps = {}

	for jump in jumplist_iter(direction) do
		local matched_predicates = {}

		for i, query in pairs(queries) do
			if identified_jumps[i] then
				goto continue
			end
			if matched_predicates[query.predicate] then
				goto continue
			end
			if query.predicate(jump) then
				matched_predicates[query.predicate] = true
				identified_jumps[i] = vim.tbl_extend("force", jump, {
					query = query,
				})
			end
			::continue::
		end
	end

	-- HACK: give non-identified jumps a "no-op" jump
	for i = 1, #queries do
		if identified_jumps[i] == nil then
			identified_jumps[i] = {
				direction = types.Direction.NONE,
				query = queries[i],
			}
		end
	end

	return identified_jumps
end

--- @param jump Portal.Jump
function M.select(jump)
	local jump_key = nil
	if jump.direction == types.Direction.BACKWARD then
		jump_key = config.keymaps.backward
	elseif jump.direction == types.Direction.FORWARD then
		jump_key = config.keymaps.forward
	elseif jump.direction == types.Direction.NONE then
		return
	end

	vim.api.nvim_feedkeys(jump.distance .. jump_key, "n", false)
end

return M
