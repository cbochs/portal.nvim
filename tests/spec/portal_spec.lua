local Iterator = require("portal.iterator")
local Portal = require("portal")

describe("portal", function()
    describe("#search", function()
        it("does not allow an empty search", function()
            -- stylua: ignore
            assert.error(
                function () Portal.search() end,
                "Must provide at least one query to Portal search"
            )
        end)

        it("returns results for a single query", function()
            -- stylua: ignore
            assert.are.same({ 1, 2, 3 }, Portal.search({
                source = Iterator:new({ 1, 2, 3 }),
            }))
        end)

        it("returns results for multiple queries", function()
            -- stylua: ignore
            assert.are.same(
                { 1, 2, 3 },
                Portal.search({
                    { source = Iterator:new({ 1 }) },
                    { source = Iterator:new({ 2, 3 }) },
                })
            )
        end)
    end)
end)
