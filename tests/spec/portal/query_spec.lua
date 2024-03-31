local Query = require("portal.query")

local function generator()
    return { 1, 2, 3, 4 }
end

describe("search", function()
    describe("#search", function()
        it("performs a simple search", function()
            local query = Query.new(generator)
            assert.are.same({ 1, 2, 3, 4 }, query:search())
        end)

        it("performs a search from a starting point", function()
            local query = Query.new(generator):prepare({
                start = 2,
            })
            assert.are.same({ 2, 3, 4 }, query:search())
        end)

        it("performs a filtered search", function()
            local query = Query.new(generator):prepare({
                filter = function(v)
                    return v % 2 == 0
                end,
            })
            assert.are.same({ 2, 4 }, query:search())
        end)

        it("performs a slotted search", function()
            -- stylua: ignore
            local query = Query.new(generator):prepare({
                slots = {
                    function(v) return v == 3 end,
                    function(v) return v == 5 end, -- DNE
                    function(v) return v == 1 end,
                }
            })

            assert.are.same({ [1] = 3, [2] = nil, [3] = 1 }, query:search())
        end)
    end)
end)
