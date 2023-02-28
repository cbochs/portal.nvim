local Iterator = require("portal.iterator")
local Search = require("portal.search")

describe("search", function()
    describe("#iter", function()
        it("returns the list if no options are provided", function()
            assert.are.same({ 1, 2, 3 }, Search.iter({ 1, 2, 3 }):collect())
        end)

        it("returns a subset of the list", function()
            assert.are.same({ 1 }, Search.iter({ 1, 2, 3 }, { max_results = 1 }):collect())
        end)

        it("filters the list", function()
            assert.are.same(
                { 1, 3 },
                Search.iter({ 1, 2, 3 }, {
                -- stylua: ignore
                filter = function(v) return v ~= 2 end,
                }):collect()
            )
        end)

        it("iterates the list backwards", function()
            assert.are.same({ 2, 1 }, Search.iter({ 1, 2 }, { direction = "backward" }):collect())
        end)
    end)

    describe("#query", function()
        it("queries the list", function()
            assert.are.same(
                { 1 },
                Search.query(Iterator:new({ 1, 2, 3 }), function(v)
                    return v ~= 2
                end)
            )
        end)
    end)
end)
