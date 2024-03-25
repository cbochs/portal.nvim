local Iter = require("portal.iterator")

-- TODO: create a list of expectations and generate tests
describe("iterator", function()
    it("handles an empty list", function()
        assert.is_nil(Iter.iter({}):next())
    end)

    it("acts as a iterator", function()
        local iter = Iter.iter({ "a", "b", "c" })
        assert.are.same({ "a" }, { iter:next() })
        assert.are.same({ "b" }, { iter:next() })
        assert.are.same({ "c" }, { iter:next() })
    end)

    it("can be iterated", function()
        local list = { "a", "b", "c" }
        for i, v in Iter.iter(list):iter() do
            assert.equals(list[i], v)
        end
    end)

    it("can be collected into a list", function()
        assert.are.same({ "a", "b" }, Iter.iter({ "a", "b" }):totable())
    end)

    it("can be reduced into a table", function()
        assert.are.same(
            { a = 1, b = 2 },
            Iter.iter({
                { "a", 1 },
                { "b", 2 },
            }):fold({}, function(acc, v, _)
                acc[v[1]] = v[2]
                return acc
            end)
        )
    end)

    it("can be flattened", function()
        local iter = Iter.iter({ { 1, 2 }, { 2, 3 } })
        assert.are.same({ 1, 2, 2, 3 }, iter:flatten():totable())
    end)

    describe("#rev", function()
        it("can be iterated in reverse", function()
            local iter = Iter.iter({ "a", "b", "c" }):rev()
            assert.are.same({ "c", "b", "a" }, iter:totable())
        end)

        it("can be reversed an even number of times", function()
            local iter = Iter.iter({ "a", "b", "c" }):rev():rev():rev():rev()
            assert.are.same({ "a", "b", "c" }, iter:totable())
        end)

        it("can be reversed an odd number of times", function()
            local iter = Iter.iter({ "a", "b", "c" }):rev():rev():rev()
            assert.are.same({ "c", "b", "a" }, iter:totable())
        end)
    end)

    describe("#skip", function()
        it("skips the first n items", function()
            local iter = Iter.iter({ 1, 2, 3, 4 }):skip(2)
            assert.are.same({ 3, 4 }, iter:totable())
        end)

        it("skips the first n items in reverse", function()
            local iter = Iter.iter({ 1, 2, 3, 4 }):skip(2):rev()
            assert.are.same({ 4, 3 }, iter:totable())
        end)

        it("skips all items", function()
            local iter = Iter.iter({ 1 }):skip(100)
            assert.are.same({}, iter:totable())
        end)
    end)

    describe("#filter", function()
        it("filters an iterator", function()
            -- stylua: ignore
            local filter = function(i) return i % 2 == 0 end
            local iter = Iter.iter({ 1, 2, 3, 4 }):filter(filter)
            assert.are.same({ 2, 4 }, iter:totable())
        end)
    end)

    describe("#take", function()
        it("takes only n values", function()
            local iter = Iter.iter({ 1, 2, 3, 4 }):take(2)
            assert.are.same({ 1, 2 }, iter:totable())
        end)
    end)

    describe("#map", function()
        it("maps the values", function()
            -- stylua: ignore
            local map = function(v) return v * 2 end
            local iter = Iter.iter({ 0, 1, 2 }):map(map)
            assert.are.same({ 0, 2, 4 }, iter:totable())
        end)

        it("skips nil values", function()
            -- stylua: ignore
            local map = function(v) if v > 0 then return v * 2 end end
            local iter = Iter.iter({ 0, 1, 2 }):map(map)
            assert.are.same({ 2, 4 }, iter:totable())
        end)
    end)
end)
