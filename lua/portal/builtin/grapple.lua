return require("portal.extension").register({
    name = "grapple",

    ---@return Portal.Result[] results, Portal.QueryOptions? defaults
    generate = function()
        local ok, _ = pcall(require, "grapple")
        if not ok then
            return {}
        end

        local tags = require("grapple").tags()

        ---@type Portal.QueryOptions
        ---@diagnostic disable-next-line: missing-fields
        local defaults = {
            direction = "forward",
            filter = function(content)
                return vim.api.nvim_buf_get_name(0) ~= content.path
            end,
        }

        return tags, defaults
    end,

    ---@param _ integer
    ---@param extended_result Portal.ExtendedResult
    ---@return Portal.Content
    transform = function(_, extended_result)
        local tag = extended_result.result

        ---@type Portal.Content
        local content = {
            type = "grapple",
            path = tag.path,
            cursor = tag.cursor,
        }

        return content
    end,

    ---@param content Portal.Content
    select = function(content)
        require("grapple").select({ path = content.path })
    end,
})
