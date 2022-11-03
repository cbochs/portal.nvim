---@type Portal.Config
local M = {}

---@class Portal.Config
local DEFAULT_CONFIG = {
    -- todo(cbochs): implement
    log_level = vim.log.levels.WARN,

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
    ---to `nil` or `false`.
    ---@type table<string, boolean | nil>
    escape = {
        ["<esc>"] = true,
    },

    ---Keycodes used for jumping forward and backward. These are not overrides
    ---of the current keymaps, but instead will be used internally when a jump
    ---is selected.
    backward = "<c-o>",
    forward = "<c-i>",

    ---
    portal = {
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
            -- When a portal is empty, render an empty buffer body
            render_empty = false,

            --- The raw window options used for the portal body window
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

    integrations = {
        ---cbochs/grapple.nvim: registers the "grapple" query item
        grapple = false,

        ---ThePrimeagen/harpoon: registers the "harpoon" query item
        harpoon = false,
    },
}

--- @type Portal.Config
local _config = DEFAULT_CONFIG

local function resolve_key(key)
    return vim.api.nvim_replace_termcodes(key, true, false, true)
end

--- @param keys table
local function resolve_keys(keys)
    local resolved_keys = {}

    for key_or_index, key_or_flag in pairs(keys) do
        -- Table style: { "a", "b", "c" }. In this case, key_or_flag is the key
        if type(key_or_index) == "number" then
            table.insert(resolved_keys, resolve_key(key_or_flag))
            goto continue
        end

        -- Table style: { ["<esc>"] = true }. In this case, key_or_index is the key
        if type(key_or_index) == "string" and key_or_flag == true then
            table.insert(resolved_keys, resolve_key(key_or_index))
            goto continue
        end

        ::continue::
    end

    return resolved_keys
end

--- @param opts? Portal.Config
function M.load(opts)
    opts = opts or {}

    --- @type Portal.Config
    _config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, opts)

    -- Resolve label keycodes
    _config.labels = resolve_keys(_config.labels)
    _config.escape = resolve_keys(_config.escape)
    _config.backward = resolve_key(_config.backward)
    _config.forward = resolve_key(_config.forward)
end

setmetatable(M, {
    __index = function(_, index)
        return _config[index]
    end,
})

return M
