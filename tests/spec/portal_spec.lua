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
