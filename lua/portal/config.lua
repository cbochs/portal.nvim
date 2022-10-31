--- @type Portal.Config
local M = {}

--- @enum Portal.Keymap
M.Keymap = {
    ---
    ESCAPE = "escape",

    ---
    FORWARD = "forward",

    ---
    BACKWARD = "backward",
}

--- @enum Portal.MarkScope
M.MarkScope = {
    --- Use a global namespace for marks
    GLOBAL = "global",

    --- Use the reported "root_dir" from LSP clients as the mark namespace
    LSP = "lsp",

    --- Use the current working directory as the mark namespace
    DIRECTORY = "directory",
}


--- @class Portal.Config
local DEFAULT_CONFIG = {
    log_level = vim.log.levels.WARN,

    mark = {
        --- The default scope in which marks will be saved to
        --- todo(cbochs): implement
        --- @type Portal.MarkScope
        scope = M.MarkScope.GLOBAL,

        --- Marks will be scoped to a specific git commit
        --- todo(cbochs): implement
        git = false
    },

    default = {
        --- The default queries used when searching the jumplist
        --- @type Portal.QueryLike
        query = { "marked", "modified", "different", "valid" },

        --- The default labels used when showing jumps
        labels = { "j", "k", "h", "l" },
    },

    window = {
        title = {
            -- When a portal is empty, render an default portal title
            -- todo(cbochs): implement
            render_empty = true,

            ---
            options = {
                relative  = "cursor",
                width     = 80, -- implement as "min/mas width",
                height    = 1,
                col       = 2,
                style     = "minimal",
                focusable = false,
                border    = "single",
                noautocmd = true,
                zindex = 98
            },
        },

        portal = {
            -- When a portal is empty, render an empty buffer body
            -- todo(cbochs): implement
            render_empty = false,

            ---
            options = {
                relative  = "cursor",
                width     = 80, -- implement as "min/mas width",
                height    = 3,  -- implement as "context lines"
                col       = 2,  -- implement as "offset"
                focusable = false,
                border    = "single",
                noautocmd = true,
                zindex = 99
            },
        },

    },

    preview = {
        -- When there is more than one jump for a single row, collapse it
        -- todo(cbochs): implement
        collapse = true,
    },

    keymaps = {
        ["<esc>"] = M.Keymap.ESCAPE,
        ["<c-j>"] = M.Keymap.ESCAPE,
        ["<c-i>"] = M.Keymap.FORWARD,
        ["<c-o>"] = M.Keymap.BACKWARD,
    },
}

local _config = DEFAULT_CONFIG

local function validate(config, expected_config)
    config = config or _config
    expected_config = expected_config or DEFAULT_CONFIG

    local errors = {}
    for key, _ in pairs(config) do
        if expected_config[key] == nil then
            table.insert(key)
        end
        if type(config[key]) == "table" then
            local nested_errors = validate(config[key], expected_config[key])
            for i, error_key in pairs(nested_errors) do
                nested_errors[i] = key .. "." .. error_key
            end
            errors = { unpack(errors), unpack(nested_errors) }
        end
    end

    return errors
end

--- @param keymaps table<string, Portal.Keymap>
--- @return table<Portal.Keymap, string[]>
local function resolve_keymaps(keymaps)
    local resolved_keymaps = {}

    for lhs, keymap in pairs(keymaps) do
        resolved_keymaps[keymap] = resolved_keymaps[keymap] or {}
        local keycode = vim.api.nvim_replace_termcodes(lhs, true, false, true)
        table.insert(resolved_keymaps[keymap], keycode)
    end

    -- There can only be one "backward" and "forward" keymap
    resolved_keymaps[M.Keymap.BACKWARD] = resolved_keymaps[M.Keymap.BACKWARD][1]
    resolved_keymaps[M.Keymap.FORWARD] = resolved_keymaps[M.Keymap.FORWARD][1]

    return resolved_keymaps
end

--- @param opts Portal.Config
function M.load(opts)
    opts = opts or {}

    local merged_config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts)
    local errors = validate(merged_config, DEFAULT_CONFIG)

    if #errors > 0 then
        error("ValidationError - Invalid options: " .. vim.inspect(errors))
        return
    end

    _config = merged_config
    _config.keymaps = resolve_keymaps(_config.keymaps)
end

setmetatable(M, {
    __index = function(_, index)
        return _config[index]
    end
})

return M
