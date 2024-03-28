local Query = require("portal.query")
local Search = require("portal.search")

local function generator()
    return { 1, 2, 3 }
end

describe("portal", function()
    describe("#search", function()
        it("returns results for a single query", function()
            local query = Query.new(generator)
            assert.are.same({ 1, 2, 3 }, Search.search(query))
        end)

        it("returns results for a list of queries", function()
            local queries = {
                Query.new(generator),
                Query.new(generator),
            }
            assert.are.same({ 1, 2, 3, 1, 2, 3 }, Search.search(queries))
        end)

        it("returns a maximum number of results", function()
            local query = Query.new(generator)
            assert.are.same({ 1 }, Search.search(query, { limit = 1 }))
        end)

        it("returns results for a set of slots", function()
            local query = Query.new(generator)

            -- stylua: ignore
            local slots = {
                function(v) return v == 3 end,
                function(v) return v == 5 end, -- DNE
                function(v) return v == 1 end,
            }

            assert.are.same({ [1] = 3, [2] = nil, [3] = 1 }, Search.search(query, { slots = slots }))
        end)
    end)
end)
