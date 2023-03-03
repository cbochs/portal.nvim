local Commands = {}

function Commands.create()
    vim.api.nvim_create_user_command("Portal", function(opts)
        local builtin = require("portal.builtin")[opts.fargs[1]]
        if not builtin then
            return
        end
        builtin.tunnel({ direction = opts.fargs[2] })
    end, {
        desc = "Open portals",
        nargs = "*",
        complete = function(_, cmd_line, _)
            local directions = { "forward", "backward" }
            local builtins = { "changelist", "jumplist", "quickfix" }

            local line_split = vim.split(cmd_line, "%s+")
            local n = #line_split - 2

            if n == 0 then
                return vim.tbl_filter(function(val)
                    return vim.startswith(val, line_split[2])
                end, builtins)
            end

            if n == 1 then
                return vim.tbl_filter(function(val)
                    return vim.startswith(val, line_split[3])
                end, directions)
            end
        end,
    })
end

return Commands
