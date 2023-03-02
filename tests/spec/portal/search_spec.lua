local Iterator = require("portal.iterator")
local Search = require("portal.search")

describe("search", function()
    describe("#search", function()
        it("collects the source iterator when no predicates are available", function()
            -- stylua: ignore
            assert.are.same({ 1, 2, 3 }, Search.search({
                source = Iterator:new({ 1, 2, 3 })
            }))
        end)

        it("performs a query when predicates are available", function()
            -- stylua: ignore
            assert.are.same({ 2 }, Search.search({
                source = Iterator:new({ 1, 2, 3 }),
                predicates = function(v) return v > 1 end
            }))
        end)

        it("can search and partially match a list of predicates", function()
            -- stylua: ignore
            assert.are.same({ [1] = 1, [3] = 3 }, Search.search({
                source = Iterator:new({ 1, 2, 3}),
                predicates = {
                    function(v) return v == 1 end,
                    function(v) return v == 5 end,
                    function(v) return v == 3 end,
                }
            }))
        end)
    end)
end)
