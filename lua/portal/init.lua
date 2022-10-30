local config = require("portal.config")

local M = {}

--- @class Portal.Options
--- @field desired Portal.Predicate[]
--- @field decorator Portal.Decorator
--- @field labeller Portal.Labeller

--- @param opts Portal.Config
function M.setup(opts)
    config.load(opts)
end

--- @param direction Portal.Direction
--- @param opts Portal.Options
function M.jump(direction, opts)
    local jump = require("portal.jump")
    local jumps = jump.generate(
        opts.desired or config.jump.desired,
        direction
    )

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

--- @param opts Portal.Options
function M.jump_backward(opts)
    M.jump(require("portal.jump").Direction.BACKWARD, opts)
end

--- @param opts Portal.Options
function M.jump_forward(opts)
    M.jump(require("portal.jump").Direction.FORWARD, opts)
end

return M
