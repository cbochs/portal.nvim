local types = require("portal.types")

local M = {}

---Keycodes used for jumping forward and backward. These are not overrides
---of the current keymaps, but instead will be used internally when a jump
---is selected.
local backward_key = vim.api.nvim_replace_termcodes("<c-o>", true, false, true)
local forward_key = vim.api.nvim_replace_termcodes("<c-i>", true, false, true)

--- @class Portal.Jump
--- @field buffer integer
--- @field direction Portal.Direction
--- @field distance integer
--- @field row integer
--- @field col integer
--- @field query Portal.Query

--- @param direction Portal.Direction
--- @param lookback integer | nil
--- @return fun(): Portal.Jump
local function jumplist_iter(direction, lookback)
    local jumplist_tuple = vim.fn.getjumplist()

    local vim_jumplist = jumplist_tuple[1]
    local start_pos = jumplist_tuple[2] + 1

    local signed_step = 1
    if direction == types.direction.backward then
        signed_step = -1
    elseif direction == types.direction.forward then
        signed_step = 1
    end

    local displacement = 0
    local distance = 0
    local current_pos = start_pos + displacement
    local max_lookback = lookback or #vim_jumplist

    return function()
        displacement = displacement + signed_step
        distance = math.abs(displacement)
        current_pos = start_pos + displacement

        if current_pos < 1 or current_pos > #vim_jumplist then
            return
        end
        if distance > max_lookback then
            return
        end

        local vim_jump = vim_jumplist[current_pos]

        --- @type Portal.Jump
        local jump = {
            buffer = vim_jump.bufnr,
            distance = distance,
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
--- Given an list of jump queries: `{ "valid", "valid", "modified" }`,
--- the resulting ordered list will be:
--- * the first jump will be associated with the first item in the jumplist
--- * the second jump will be associated with the second item in the jumplist
--- * if the first jump was also modified, the third jump will also be
---   associated with the first item in the jumplist
---
--- @param queries Portal.Query[]
--- @param direction Portal.Direction
--- @param opts? { lookback?: integer }
--- @return Portal.Jump[]
function M.search(queries, direction, opts)
    opts = opts or {}

    --- @type Portal.Jump[]
    local identified_jumps = {}

    for jump in jumplist_iter(direction, opts.lookback) do
        local matched_predicates = {}

        for i, query in pairs(queries) do
            if identified_jumps[i] then
                goto continue
            end
            if matched_predicates[query.predicate] then
                goto continue
            end
            if query(jump) then
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
                direction = types.direction.none,
                query = queries[i],
            }
        end
    end

    return identified_jumps
end

--- @param jump Portal.Jump
function M.select(jump)
    local jump_key = nil
    if jump.direction == types.direction.backward then
        jump_key = backward_key
    elseif jump.direction == types.direction.forward then
        jump_key = forward_key
    elseif jump.direction == types.direction.none then
        return
    end

    vim.api.nvim_feedkeys(jump.distance .. jump_key, "n", false)
end

return M
