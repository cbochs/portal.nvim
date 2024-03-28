local Settings = require("portal.settings")

describe("settings", function()
    it("has the correct defaults", function()
        local settings = Settings.new()

        assert.are.same({ "j", "k", "h", "l" }, settings.labels)
        assert.are.same(false, settings.select_first)
        assert.are.same(nil, settings.slots)
        assert.are.same(nil, settings.filter)
        assert.equals(100, settings.lookback)

        assert.are.same({
            width = 80,
            height = 3,

            relative = "cursor",
            col = 2,

            focusable = false,
            border = "single",
            style = "minimal",
            noautocmd = true,

            -- Exclude default title function from test
            title = settings.window_options.title,
        }, settings.window_options)
    end)
end)
