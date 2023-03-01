local Iterator = require("portal.iterator")
local Search = require("portal.search")

describe("search", function()
    describe("#search", function()
        it("returns a filtered list", function()
            -- stylua: ignore
            assert.are.same(
                { 1, 2 },
                Search.search({ 1, 2, 3 }, {
                    filter = function(v) return v < 3 end,
                })
            )
        end)

        it("returns a queries list", function()
            -- stylua: ignore
            assert.are.same(
                { 2, 2, 1 },
                Search.search({ 1, 2, 3 }, {
                    query = {
                        function(v) return v == 2 end,
                        function(v) return v > 1 end,
                        function(v) return v == 1 end,
                    },
                })
            )
        end)
    end)

    describe("#iter", function()
        it("returns the list if no options are provided", function()
            assert.are.same({ 1, 2, 3 }, Search.iter({ 1, 2, 3 }):collect())
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

        it("maps the list", function()
            assert.are.same(
                { 2, 4 },
                Search.iter({ 1, 2 }, {
                    -- stylua: ignore
                    map = function(v) return v * 2 end,
                }):collect()
            )
        end)

        it("iterates the list backwards", function()
            assert.are.same({ 2, 1 }, Search.iter({ 1, 2 }, { direction = "backward" }):collect())
        end)

        it("iterates from a start index", function()
            assert.are.same({ 2, 3 }, Search.iter({ 1, 2, 3 }, { start = 2 }):collect())
        end)

        it("iterates over a subset of the list", function()
            assert.are.same({ 1 }, Search.iter({ 1, 2, 3 }, { max_results = 1 }):collect())
        end)
    end)

    describe("#query", function()
        it("can query the list", function()
            assert.are.same(
                { 1 },
                Search.query(Iterator:new({ 1, 2, 3 }), function(v)
                    return v ~= 2
                end)
            )
        end)

        it("can query for duplicate matches", function()
            assert.are.same(
                { 1, 1 },
                Search.query(Iterator:new({ 1, 2, 3 }), {
                    -- stylua: ignore
                    function(v) return v ~= 2 end,
                    -- stylua: ignore
                    function(v) return v < 2 end,
                })
            )
        end)
    end)
end)
