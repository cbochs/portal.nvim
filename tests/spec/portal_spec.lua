local Portal = require("portal")

describe("portal", function()
    describe("#search", function()
        it("returns a filtered list", function()
            assert.are.same(
                { 1, 2 },
                Portal.search({ 1, 2, 3 }, {
                    -- stylua: ignore
                    filter = function(v) return v < 3 end,
                })
            )
        end)

        it("returns a queries list", function()
            assert.are.same(
                { 2, 2, 1 },
                Portal.search({ 1, 2, 3 }, {
                    query = {
                        -- stylua: ignore
                        function(v) return v == 2 end,
                        -- stylua: ignore
                        function(v) return v > 1 end,
                        -- stylua: ignore
                        function(v) return v == 1 end,
                    },
                })
            )
        end)
    end)

    describe("#jump", function() end)
end)
