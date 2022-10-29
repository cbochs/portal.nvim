local config = require("grapple.config")

local M = {}

--- @class Grapple.Jump
--- @field buffer integer
--- @field direction Grapple.Direction
--- @field distance integer
--- @field row integer
--- @field col integer

--- @enum Grapple.Direction
M.Direction = {
    BACKWARD = 0,
    FORWARD = 1,
    NONE = 2,
}

--- @return Grapple.Jump
local function default()
    return  {
        buffer = -1,
        direction = M.Direction.NONE,
        distance = 0,
        row = 0,
        col = 0,
    }
end

--- @param direction Grapple.Direction
--- @return fun(): Grapple.Jump
local function jumplist_iter(direction)
    local jumplist_tuple = vim.fn.getjumplist()

    local vim_jumplist = jumplist_tuple[1]
    local start_pos = jumplist_tuple[2] + 1

    local signed_step = 1
    if direction == M.Direction.BACKWARD then
        signed_step = -1
    elseif direction == M.Direction.FORWARD then
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

        --- @type Grapple.Jump
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
--- predicates.
---
--- In order to generate unique jumps, an individual jump may only be
--- associated with a unique predicate _type_ once. However, a jump may be
--- associated with more than one predicate.
---
--- For example, given an list of jump predicates `{ is_jump, is_jump, is_mark }`,
--- the resulting ordered list will be:
--- * the first jump will be associated with the first item in the jumplist
--- * the second jump will be associated with the second item in the jumplist
--- * if the first jump was also `marked`, the third jump will also be
---   associated with the first item in the jumplist
---
--- @param desired_jumps Grapple.Predicate[]
--- @param direction Grapple.Direction
--- @return Grapple.Jump[]
function M.generate(desired_jumps, direction)
    --- @type Grapple.Jump[]
    local identified_jumps = {}

    for jump in jumplist_iter(direction) do
        local matched_predicates = {}

        for i, predicate in pairs(desired_jumps) do
            if identified_jumps[i] then
                goto continue
            end
            if matched_predicates[predicate] then
                goto continue
            end
            if predicate(jump) then
                matched_predicates[predicate] = true
                identified_jumps[i] = jump
            end
            ::continue::
        end
    end

    -- HACK: give non-identified jumps a "no-op" jump
    for i = 1, #desired_jumps do
        if identified_jumps[i] == nil then
            identified_jumps[i] = default()
        end
    end

    return identified_jumps
end

--- @param jump Grapple.Jump
function M.select(jump)
    local jump_key = nil
    if jump.direction == M.Direction.BACKWARD then
        jump_key = config.keymaps.backward
    elseif jump.direction == M.Direction.FORWARD then
        jump_key = config.keymaps.forward
    elseif jump.direction == M.Direction.NONE then
        return
    end

    vim.api.nvim_feedkeys(jump.distance .. jump_key, "n", false)
end

--- @return string | nil
local function get_input()
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
        return nil
    end

    for _, keycode in pairs(config.keymaps.escape) do
        if char == keycode then
            return nil
        end
    end

    return char
end

--- @param jumps Grapple.Jump[]
--- @param labeller Grapple.Labeller
--- @return boolean
function M.resolve(jumps, labeller)
    local input_char = get_input()
    if input_char == nil then
        return true
    end

    for index, jump in pairs(jumps) do
        local label = labeller(index, jump)
        if input_char == label and jump.direction ~= M.Direction.NONE then
            M.select(jump)
            return true
        end
    end

    return false
end

return M
