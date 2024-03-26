local Iter = require("portal.iterator")
local Query = require("portal.query")

local function generator()
    return Iter.iter({ 0, 1, 2, 3, 4 })
end

describe("search", function()
    describe("#search", function()
        it("performs a search", function()
            local query = Query.new(generator)
            assert.are.same({ 0, 1, 2, 3, 4 }, query:search():totable())
        end)

        it("performs a filtered search", function()
            local query = Query.new(generator):prepare({
                filter = function(v)
                    return v % 2 == 0
                end,
            })
            assert.are.same({ 0, 2, 4 }, query:search():totable())
        end)
    end)
end)
