local Iter = require("portal.iterator")
local Query = require("portal.query")
local Search = require("portal.search")

local function generator()
    return Iter.iter({ 1, 2, 3 })
end

describe("portal", function()
    describe("#search", function()
        it("returns results for a set of queries", function()
            local queries = {
                Query.new(generator),
                Query.new(generator),
            }
            assert.are.same({ 1, 2, 3, 1, 2, 3 }, Search.search(queries))
        end)

        it("returns a maximum number of results", function()
            local queries = { Query.new(generator) }
            assert.are.same({ 1 }, Search.search(queries, 1))
        end)

        it("returns results for a set of slots", function()
            local queries = { Query.new(generator) }

            -- stylua: ignore
            assert.are.same({ 3, 1 }, Search.search(queries, {
                function(v) return v == 3 end,
                function(v) return v == 1 end,
            }))
        end)
    end)
end)
