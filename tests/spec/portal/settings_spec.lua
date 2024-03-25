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

            title = nil,
            title_pos = "center",
        }, settings.win_opts)
    end)
end)
