---@class Portal.Settings
local Settings = {}
Settings.__index = function(tbl, key)
    return Settings[key] or tbl.inner[key]
end

---@class Portal.Settings
local DEFAULT_SETTINGS = {
    ---Ordered list of keys for labelling portals
    ---@type string[]
    labels = { "j", "k", "h", "l" },

    ---Select the first portal when there is only one result
    ---@type boolean
    select_first = false,

    ---The maximum number of results to return or a list of predicates to match
    ---or "fill". By default, uses the number of labels as a maximum number of
    ---results. See the Slots section for more information.
    ---@type Portal.Slots | nil
    slots = nil,

    ---The default filter to be applied to every search result.
    ---@type Portal.Predicate | nil
    filter = nil,

    ---The maximum number of results to consider when performing a Portal query
    ---@type integer
    lookback = 100,

    ---Window options for Portal windows
    ---@type vim.api.keyset.win_config
    win_opts = {
        width = 80,
        height = 3,

        relative = "cursor",
        col = 2,

        focusable = false,
        border = "single",
        style = "minimal",
        noautocmd = true,

        ---@type string | fun(c: Portal.Content): string | nil
        title = function(content)
            local title = vim.fs.basename(content.path or vim.api.nvim_buf_get_name(content.buffer))
            if title == "" then
                title = "content"
            end
            return ("[%s] %s"):format(content.type, title)
        end,

        title_pos = "center",
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

---@return Portal.Settings
function Settings.new()
    return setmetatable({
        inner = vim.deepcopy(DEFAULT_SETTINGS),
    }, Settings)
end

-- Update settings in-place
---@param opts? Portal.Settings
function Settings:update(opts)
    self.inner = vim.tbl_deep_extend("force", self.inner, opts or {})
    self.inner.labels = replace_termcodes(self.inner.labels)
end

---A global instance of the Portal settings
---@type Portal.Settings
local settings

---A wrapper around Settings to enable directly indexing the global instance
local SettingsMod = {}

---@return Portal.Settings
function SettingsMod.new()
    return Settings.new()
end

setmetatable(SettingsMod, {
    __index = function(_, key)
        if not settings then
            settings = Settings.new()
        end
        return settings[key]
    end,
})

return SettingsMod
