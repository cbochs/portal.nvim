local Commands = {}

function Commands.create()
    vim.api.nvim_create_user_command("Portal", function(opts)
        local builtin = require("portal.builtin")[opts.fargs[1]]
        if not builtin then
            error(("'%s' is not a valid Portal builtin"):format(builtin))
        end

        local direction = opts.fargs[2]
        if not vim.tbl_contains({ "forward", "backward" }, direction) then
            error(("'%s' is not a valid direction. Use either 'forward' or 'backward'"):format(direction))
        end

        builtin.tunnel({ direction = opts.fargs[2] })
    end, {
        desc = "Open portals",
        nargs = "*",
        complete = function(_, cmd_line, _)
            local line_split = vim.split(cmd_line, "%s+")
            local n = #line_split - 2

            if n == 0 then
                local builtins = {
                    "changelist",
                    "grapple",
                    "harpoon",
                    "jumplist",
                    "quickfix",
                }

                return vim.tbl_filter(function(val)
                    return vim.startswith(val, line_split[2])
                end, builtins)
            end

            if n == 1 then
                local directions = { "forward", "backward" }

                return vim.tbl_filter(function(val)
                    return vim.startswith(val, line_split[3])
                end, directions)
            end
        end,
    })
end

return Commands
