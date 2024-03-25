local Iter = require("portal.iterator")
local Query = require("portal.query")

local function generator()
    return Iter.iter({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })
end

describe("search", function()
    describe("#search", function()
        it("performs a search", function()
            local query = Query.new(generator)
            assert.are.same({ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }, query:search())
        end)

        it("searches for a set number of slots", function()
            local query = Query.new(generator)
            assert.are.same({ 0, 1, 2 }, query:search(3))
        end)

        it("searches for a set specific set of slots", function()
            local query = Query.new(generator)

            -- stylua: ignore
            local slots = {
                function(v) return v % 2 == 0 end,
                function(v) return v % 2 == 0 end,
                function(v) return v % 2 == 0 end,
            }

            assert.are.same({ 0, 2, 4 }, query:search(slots))
        end)
    end)
end)
