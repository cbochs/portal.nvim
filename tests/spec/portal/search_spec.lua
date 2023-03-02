local Iterator = require("portal.iterator")
local Search = require("portal.search")

describe("search", function()
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
            -- stylua: ignore
            assert.are.same(
                { 1, 1 },
                Search.query(Iterator:new({ 1, 2, 3 }), {
                    function(v) return v ~= 2 end,
                    function(v) return v < 2 end,
                })
            )
        end)

        it("can have a holey query", function()
            -- stylua: ignore
            assert.are.same(
                { [1] = 1, [3] = 3 },
                Search.query(Iterator:new({ 1, 2, 3 }), {
                    function(v) return v == 1 end,
                    function(v) return v == 5 end,
                    function(v) return v == 3 end,
                })
            )
        end)
    end)
end)
