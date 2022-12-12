---@type Portal.Settings
local settings = {}

---@class Portal.Settings
local DEFAULT_SETTINGS = {
    ---@type "debug" | "info" | "warn" | "error"
    log_level = "warn",

    ---The default queries used when searching the jumplist. An entry can
    ---be a name of a registered query item, an anonymous predicate, or
    ---a well-formed query item. See Queries section for more information.
    ---@type Portal.QueryLike[]
    query = { "modified", "different", "valid" },

    ---An ordered list of keys that will be used for labelling available jumps.
    ---Labels will be applied in same order as `query`.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Keys used for exiting portal selection. To disable a key, set its value
    ---to `false`.
    ---@type table<string, boolean>
    escape = {
        ["<esc>"] = true,
    },

    ---The jumplist is fixed at 100 items, which has the possibility to impact
    ---portal performance. Set this to a value less than 100 to limit the number
    ---of jumps in the jumplist that will be queried.
    lookback = 100,

    ---Keycodes used for jumping forward and backward. These are not overrides
    ---of the current keymaps, but instead will be used internally when a jump
    ---is selected.
    backward = "<c-o>",
    forward = "<c-i>",

    ---
    portal = {
        ---feat(nvim-0.9) When a portal is empty, render an default portal title
        render_empty = true,

        ---feat(nvim-0.9) The raw window options used for the portal window
        options = {
            relative = "cursor",
            width = 80, -- implement as "min/max width",
            height = 3, -- implement as "context lines"
            col = 2, -- implement as "offset"
            focusable = false,
            border = "single",
            noautocmd = true,
        },

        title = {
            ---When a portal is empty, render an default portal title
            render_empty = true,

            ---The raw window options used for the portal title window
            options = {
                relative = "cursor",
                width = 80, -- implement as "min/mas width",
                height = 1,
                col = 2,
                style = "minimal",
                focusable = false,
                border = "single",
                noautocmd = true,
                zindex = 98,
            },
        },

        body = {
            ---When a portal is empty, render an empty buffer body
            render_empty = false,

            ---The raw window options used for the portal body window
            options = {
                relative = "cursor",
                width = 80, -- implement as "min/max width",
                height = 3, -- implement as "context lines"
                col = 2, -- implement as "offset"
                focusable = false,
                border = "single",
                noautocmd = true,
                zindex = 99,
            },
        },
    },
}

local function termcode_for(key)
    return vim.api.nvim_replace_termcodes(key, true, false, true)
end

--- @param keys table
local function replace_termcodes(keys)
    local resolved_keys = {}

    for key_or_index, key_or_flag in pairs(keys) do
        -- Table style: { "a", "b", "c" }. In this case, key_or_flag is the key
        if type(key_or_index) == "number" then
            table.insert(resolved_keys, termcode_for(key_or_flag))
            goto continue
        end

        -- Table style: { ["<esc>"] = true }. In this case, key_or_index is the key
        if type(key_or_index) == "string" and key_or_flag == true then
            table.insert(resolved_keys, termcode_for(key_or_index))
            goto continue
        end

        ::continue::
    end

    return resolved_keys
end

--- @type Portal.Settings
local _settings = DEFAULT_SETTINGS
_settings.escape = replace_termcodes(_settings.escape)
_settings.labels = replace_termcodes(_settings.labels)

---@param overrides? Portal.Settings
function settings.update(overrides)
    _settings = vim.tbl_deep_extend("force", DEFAULT_SETTINGS, overrides or {})
    _settings.escape = replace_termcodes(_settings.escape)
    _settings.labels = replace_termcodes(_settings.labels)
end

setmetatable(settings, {
    __index = function(_, index)
        return _settings[index]
    end,
})

return settings
