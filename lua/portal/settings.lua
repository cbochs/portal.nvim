---@type Portal.Settings
local Settings = {}

---@class Portal.Settings
local DEFAULT_SETTINGS = {
    ---@type "debug" | "info" | "warn" | "error"
    log_level = "warn",

    ---The base filter applied to every search.
    ---@type Portal.SearchPredicate | nil
    filter = nil,

    ---The maximum number of results for any search.
    ---@type integer | nil
    max_results = nil,

    ---The maximum number of items that can be searched.
    ---@type integer
    lookback = 100,

    ---An ordered list of keys for labelling portals.
    ---Labels will be applied in order, or to match slotted results.
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Keys used for exiting portal selection. Disable with [{key}] = false
    ---to `false`.
    ---@type table<string, boolean>
    escape = {
        ["<esc>"] = true,
    },

    ---The raw window options used for the portal window
    window_options = {
        relative = "cursor",
        width = 80,
        height = 3,
        col = 2,
        focusable = false,
        border = "single",
        noautocmd = true,
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
function Settings.update(overrides)
    _settings = vim.tbl_deep_extend("force", DEFAULT_SETTINGS, overrides or {})
    _settings.escape = replace_termcodes(_settings.escape)
    _settings.labels = replace_termcodes(_settings.labels)
end

setmetatable(Settings, {
    __index = function(_, index)
        return _settings[index]
    end,
})

return Settings
