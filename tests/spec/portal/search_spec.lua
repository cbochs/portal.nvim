local Iter = require("portal.iterator")
local Query = require("portal.query")
local Search = require("portal.search")

local function generator()
    return Iter.iter({ 1, 2, 3 })
end

describe("portal", function()
    describe("#search", function()
        it("returns results for a single query", function()
            local query = Query.new(generator)
            assert.are.same({ 1, 2, 3 }, Search.search(query))
        end)

        it("returns results for multiple queries", function()
            local queries = {
                Query.new(generator),
                Query.new(generator),
            }
            assert.are.same({ 1, 2, 3, 1, 2, 3 }, Search.search(queries))
        end)
    end)
end)
