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
