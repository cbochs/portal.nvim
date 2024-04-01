local Portal = require("portal")
local Query = require("portal.query")

local function generator()
    return { 1, 2, 3 }
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

    describe("#match", function()
        it("matches a single predicate", function()
            assert.are.same(
                { [1] = 2 },
                Portal.match({ 1, 2, 3 }, function(v)
                    return v == 2
                end)
            )
        end)

        it("matches multiple predicates", function()
            -- stylua: ignore
            assert.are.same(
                { [1] = 2, [2] = 1  },
                Portal.match({ 1, 2, 3 }, {
                    function(v) return v == 2 end,
                    function(v) return v == 1 end
                })
            )
        end)

        it("matches with holes", function()
            -- stylua: ignore
            assert.are.same(
                { [1] = 2, [2] = nil, [3] = 1  },
                Portal.match({ 1, 2, 3 }, {
                    function(v) return v == 2 end,
                    function(v) return v == 100 end, -- will not match
                    function(v) return v == 1 end
                })
            )
        end)

        it("matches a table exactly", function()
            assert.are.same(
                { [1] = { type = "b", name = "bob" } },
                Portal.match({
                    { type = "a", name = "alice" },
                    { type = "b", name = "bob" },
                }, {
                    { type = "b" },
                })
            )
        end)

        it("matches a table one-of", function()
            assert.are.same(
                { [1] = { type = "b", name = "bob" } },
                Portal.match({
                    { type = "a", name = "alice" },
                    { type = "b", name = "bob" },
                }, {
                    { type = { "a", "b" }, name = "bob" },
                })
            )
        end)
    end)
end)
