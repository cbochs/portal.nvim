return {
    tunnel = function(opts)
        local Portal = require("portal")
        local Settings = require("portal.settings")

        local jumplist, start = unpack(vim.fn.getjumplist())

        opts = opts or {}
        opts = vim.tbl_extend("force", {
            list = jumplist,
            start = start,
            direction = "backward",
            map = function(v, i)
                return {
                    buffer = v.bufnr,
                    cursor = { row = v.lnum, col = v.col },
                    select = function(content)
                        local keycode = vim.api.nvim_replace_termcodes("<c-o>", true, false, true)
                        if content.direction == "forward" then
                            keycode = vim.api.nvim_replace_termcodes("<c-i>", true, false, true)
                        end
                        vim.api.nvim_feedkeys(content.distance .. keycode, "n", false)
                    end,
                    direction = opts.direction,
                    distance = math.abs(opts.start - i + 1),
                }
            end,
            filter = Settings.filter,
            query = Settings.query,
            max_results = Settings.max_results,
        }, opts)

        Portal.tunnel(opts)
    end,
}
