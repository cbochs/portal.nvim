local Iter = require("portal.iterator")
local Query = require("portal.query")
local Portal = require("portal")

local function generator()
    return Iter.iter({ 1, 2, 3 })
end

describe("portal", function()
    describe("#search", function()
        it("returns results for a single query", function()
            local query = Query.new(generator)
            assert.are.same({ 1, 2, 3 }, Portal.search(query))
        end)

        it("returns results for multiple queries", function()
            assert.are.same(
                { 1, 2, 3, 1, 2, 3 },
                Portal.search({
                    Query.new(generator),
                    Query.new(generator),
                })
            )
        end)
    end)
end)
