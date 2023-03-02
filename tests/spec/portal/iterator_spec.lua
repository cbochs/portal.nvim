local Iterator = require("portal.iterator")

describe("iterator", function()
    it("handles an empty list", function()
        assert.is_nil(Iterator:new():next())
    end)

    it("acts as a stateless iterator", function()
        local iter = Iterator:new({ "a", "b", "c" })
        assert.are.same({ 2, "b" }, { iter:next(1) })
        assert.are.same({ 1, "a" }, { iter:next(0) })
        assert.are.same({ 3, "c" }, { iter:next(2) })
    end)

    it("can be iterated", function()
        local list = { "a", "b", "c" }
        for i, v in Iterator:new(list):iter() do
            assert.equals(list[i], v)
        end
    end)

    it("can be collected into a list", function()
        assert.are.same({ "a", "b" }, Iterator:new({ "a", "b" }):collect())
    end)

    it("can be collected into a table", function()
        assert.are.same(
            { a = 1, b = 2 },
            Iterator:new({
                { "a", 1 },
                { "b", 2 },
            }):collect_table()
        )
    end)

    it("can be reduced into a table", function()
        assert.are.same(
            { a = 1, b = 2 },
            Iterator:new({
                { "a", 1 },
                { "b", 2 },
            }):reduce(function(acc, v, _)
                acc[v[1]] = v[2]
                return acc
            end, {})
        )
    end)

    it("can start at an arbitraty index", function()
        local iter = Iterator:new({ 1, 2, 3, 4, 5, 6 }):start_at(5)
        assert.are.same({ 5, 6 }, iter:collect())
    end)

    it("can be exhausted", function()
        assert.are.same({ "a", "b", "c" }, Iterator:new({ "a", "b", "c" }):collect())
    end)

    it("can chain anything", function()
        -- stylua: ignore
        local iter = Iterator:new({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 })
            :filter(function(v) return v % 2 == 0 end)
            :map(function(v) return v + 1 end)
            :reverse()
            :step_by(2)
            :take(2)
        assert.are.same({ 11, 7 }, iter:collect())
    end)

    describe("#revserse", function()
        it("can be iterated in reverse", function()
            local iter = Iterator:new({ "a", "b", "c" }):reverse()
            assert.are.same({ "c", "b", "a" }, iter:collect())
        end)

        it("can be iterated in reverse from the start", function()
            local iter = Iterator:new({ "a", "b", "c" }):start_at(1):reverse()
            assert.are.same({ "a" }, iter:collect())
        end)

        it("can be iterated in reverse starting at 1 and skipping 1", function()
            local iter = Iterator:new({ "a", "b", "c" }):start_at(1):skip(1):reverse()
            assert.are.same({}, iter:collect())
        end)
    end)

    describe("#rrepeat", function()
        it("repeats forever", function()
            local iter = Iterator:rrepeat(1):take(3)
            assert.are.same({ 1, 1, 1 }, iter:collect())
        end)

        it("repeats anything", function()
            local iter = Iterator:rrepeat({}):take(3)
            assert.are.same({ {}, {}, {} }, iter:collect())
        end)
    end)

    describe("#skip", function()
        it("skips the first n items", function()
            local iter = Iterator:new({ 1, 2, 3 }):skip(2)
            assert.are.same({ 3 }, iter:collect())
        end)

        it("skips the first n items in reverse", function()
            local iter = Iterator:new({ 1, 2, 3 }):skip(2):reverse()
            assert.are.same({ 1 }, iter:collect())
        end)

        it("skips all items", function()
            local iter = Iterator:new({ 1 }):skip(100)
            assert.are.same({}, iter:collect())
        end)
    end)

    describe("#step_by", function()
        it("steps over the iterator", function()
            local iter = Iterator:new({ 0, 1, 2, 3, 4 }):step_by(3)
            assert.are.same({ 0, 3 }, iter:collect())
        end)
    end)

    describe("#filter", function()
        it("filters an iterator", function()
            -- stylua: ignore
            local filter = function(i) return i % 2 == 0 end
            local iter = Iterator:new({ 0, 1, 2, 3, 4 }):filter(filter)
            assert.are.same({ 0, 2, 4 }, iter:collect())
        end)
    end)

    describe("#take", function()
        it("takes only n values", function()
            local iter = Iterator:new({ 0, 1, 2, 3, 4 }):take(2)
            assert.are.same({ 0, 1 }, iter:collect())
        end)
    end)

    describe("#map", function()
        it("maps the values", function()
            -- stylua: ignore
            local map = function(v) return v * 2 end
            local iter = Iterator:new({ 0, 1, 2 }):map(map)
            assert.are.same({ 0, 2, 4 }, iter:collect())
        end)

        it("skips nil values", function()
            -- stylua: ignore
            local map = function(v) if v > 0 then return v * 2 end end
            local iter = Iterator:new({ 0, 1, 2 }):map(map)
            assert.are.same({ 2, 4 }, iter:collect())
        end)
    end)
end)
