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

    ---The default filter to be applied to a Portal search
    ---@type Portal.Predicate | nil
    filter = nil,

    ---The maximum number of results to consider when performing a Portal query
    ---@type integer
    lookback = 100,

    ---An exact set of results to search for.
    ---See :h portal.nvim-slots for more information.
    ---@type Portal.Predicate[] | nil
    slots = nil,

    ---Window options for Portal windows
    ---@type vim.api.keyset.win_config
    window_options = {
        width = 80,
        height = 3,

        relative = "cursor",
        col = 2,

        focusable = false,
        border = "single",
        style = "minimal",
        noautocmd = true,

        ---@type fun(c: Portal.Content): string | nil
        title = function(content)
            local title = ""
            if content.path then
                ---@diagnostic disable-next-line: cast-local-type
                title = vim.fs.basename(content.path)
            elseif content.buffer then
                local path = vim.api.nvim_buf_get_name(content.buffer)
                local filetype = vim.api.nvim_get_option_value("filetype", { buf = content.buffer })
                if path ~= "" then
                    title = vim.fs.basename(path)
                elseif filetype ~= "" then
                    title = filetype
                else
                    title = "[No Name]"
                end
            end

            return ("[%s] %s"):format(content.type, title)
        end,
    },
}

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
