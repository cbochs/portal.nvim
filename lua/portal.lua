local input = require("portal.input")
local jump = require("portal.jump")
local query = require("portal.query")
local settings = require("portal.settings")
local types = require("portal.types")

local M = {}

local initialized = false

---@class Portal.Options
---@field query Portal.QueryLike[]
---@field previewer Portal.Previewer

function M.initialize()
    if initialized then
        return
    end
    initialized = true

    require("portal.highlight").load()

    require("portal.integrations.grapple").register()
    require("portal.integrations.harpoon").register()
end

--- @param opts? Portal.Settings
function M.setup(opts)
    settings.update(opts)
    require("portal.log").global({ log_level = settings.log_level })

    M.initialize()
end

--- @param direction Portal.Direction
--- @param opts? Portal.Options
function M.jump(direction, opts)
    opts = opts or {}

    local queries = query.resolve(opts.query or settings.query)
    local jumps = jump.search(queries, direction, { lookback = settings.lookback })

    local previewer = opts.previewer or require("portal.previewer")
    local portals = M.open(jumps, previewer)

    M.select(portals)
    M.close(portals, previewer)
end

--- @param opts? Portal.Options
function M.jump_backward(opts)
    M.jump(types.direction.backward, opts)
end

--- @param opts? Portal.Options
function M.jump_forward(opts)
    M.jump(types.direction.forward, opts)
end

--- @param jumps Portal.Jump[]
--- @param previewer Portal.Previewer
--- @return Portal.Portal[]
function M.open(jumps, previewer)
    local portals = previewer.open(jumps)

    -- Force UI to redraw to avoid user input blocking preview windows from
    -- showing up.
    vim.cmd("redraw")

    return portals
end

--- @param portals Portal.Portal[]
function M.select(portals)
    local available_labels = vim.tbl_map(function(portal)
        return portal.label
    end, portals)

    if #available_labels == 0 then
        return
    end

    while true do
        local input_label = input.get_label()
        if input_label == nil then
            break
        end

        for _, portal in pairs(portals) do
            if portal.jump.direction == types.direction.none then
                goto continue
            end
            if input_label == portal.label then
                jump.select(portal.jump)
                goto exit
            end
            ::continue::
        end
    end
    ::exit::
end

--- @param portals Portal.Portal[]
--- @param previewer Portal.Previewer
function M.close(portals, previewer)
    previewer.close(portals)
end

return M
