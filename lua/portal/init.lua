local config = require("portal.config")

local M = {}

--- @class Portal.Options
--- @field queries Portal.QueryLike[]
--- @field decorator Portal.Decorator
--- @field labeller Portal.Labeller

--- @param opts? Portal.Config
function M.setup(opts)
    config.load(opts or {})
end

--- @param direction Portal.Direction
--- @param opts? Portal.Options
function M.jump(direction, opts)
    opts = opts or {}

    local query = require("portal.query")
    local queries = query.resolve(opts.queries or config.default.query)

    local jump = require("portal.jump")
    local jumps = jump.search(queries, direction)

    local decorator = opts.decorator or require("portal.decorator").default
    local labeller = opts.labeller or require("portal.labeller").default

    local preview = require("portal.preview")
    preview.preview_jumps(jumps, decorator, labeller)

    while true do
        local resolved = jump.resolve(jumps, labeller)
        if resolved then break end
    end

    preview.clear()
end

--- @param opts? Portal.Options
function M.jump_backward(opts)
    M.jump(require("portal.jump").Direction.BACKWARD, opts)
end

--- @param opts? Portal.Options
function M.jump_forward(opts)
    M.jump(require("portal.jump").Direction.FORWARD, opts)
end

return M
