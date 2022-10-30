local M = {}

--- @class Portal.Decorations
--- @field nui_popup fun(): table
--- @field extmark fun(prev_details?: table): table
--- @field window fun(): table

--- @alias Portal.Decorator fun(index: integer, jump: Grapple.Jump, labeller: Grapple.Labeller): Grapple.Decorations

--- @param index integer
--- @param jump Portal.Jump
--- @param labeller Portal.Labeller
--- @return Portal.Decorations
function M.default(index, jump, labeller)
    return {
        nui_popup = function()
            return {
                position = {
                    row = (index - 1) * 5,
                    col = 2,
                },
                size = {
                    width = 80,
                    height = 3,
                },
                enter = false,
                focusable = false,
                relative = "cursor",
                border = {
                    style = "rounded",
                    text = {
                        top = vim.api.nvim_buf_get_name(jump.buffer),
                        top_align = "left"
                    },
                    win_options = {
                        winblend = 10,
                    }
                }
            }
        end,
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
            local predicate = require("portal.predicate")

            local virt_text = "[" .. labeller(index, jump) .. "]"
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
