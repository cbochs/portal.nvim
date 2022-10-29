local M = {}

--- @class Grapple.Decorations
--- @field extmark fun(prev_details?: table): table
--- @field window fun(): table

--- @alias Grapple.Decorator fun(index: integer, jump: Grapple.Jump): Grapple.Decorations

--- @param index integer
--- @param jump Grapple.Jump
--- @return Grapple.Decorations
function M.default(index, jump)
    return {
        window = function()
             return {
                relative  = "cursor",
                width     = 80, -- opts.window.width,
                height    = 3,  -- opts.window.height,
                row       = (index - 1) * 5,
                col       = 2,  -- opts.window.offset,
                focusable = false,
                border    = "rounded",
                noautocmd = true,
            }
        end,
        extmark = function(prev_details)
            local config = require("grapple.config")
            local predicate = require("grapple.predicate")

            local virt_text = "[" .. config.decorate.labels[index] .. "]"
            if prev_details ~= nil then
                virt_text = prev_details.virt_text[1][1] .. " " .. virt_text
            end

            local sign_text = ""
            if predicate.is_marked(jump) then
                sign_text = "MK"
            elseif predicate.is_modified(jump) then
                sign_text = "MD"
            end

            return {
                virt_text = {{ virt_text, "LeapLabelPrimary" }},
                virt_text_pos = "overlay",
                sign_text = sign_text,
                sign_hl_group = "LeapLabelPrimary",
            }
        end,
    }
end

return M
