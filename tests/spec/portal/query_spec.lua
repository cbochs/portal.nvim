local Query = require("portal.query")

local function generator()
    return { 0, 1, 2, 3, 4 }
end

describe("search", function()
    describe("#search", function()
        it("performs a simple search", function()
            local query = Query.new(generator)
            assert.are.same({ 0, 1, 2, 3, 4 }, query:search():totable())
        end)

        it("performs a search from a starting point", function()
            local query = Query.new(generator):prepare({
                start = 2,
            })
            assert.are.same({ 1, 2, 3, 4 }, query:search():totable())
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
