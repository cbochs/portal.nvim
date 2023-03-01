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

    it("can be iterated in reverse", function()
        local iter = Iterator:new({ "a", "b", "c" }):reverse()
        assert.are.same({ "c", "b", "a" }, iter:collect())
    end)

    it("can be exhausted", function()
        assert.are.same({ "a", "b", "c" }, Iterator:new({ "a", "b", "c" }):collect())
    end)

    it("can handle chained arguments", function()
        local iter = Iterator:new({ "a", "b", "c" }):reverse():start_at(2)
        assert.are.same({ "b", "a" }, iter:collect())
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
    end)

    -- describe("#search", function()
    --     it("searches for specific values", function()
    --         -- stylua: ignore
    --         local search = {
    --             function(v) return v == 5 end,
    --             function(v) return v == 4 end,
    --             function(v) return v == 2 end,
    --         }
    --
    --         local iter = Iterator:new({ 0, 1, 2, 3, 4 }):search(search)
    --         assert.are.same({ [2] = 4, [3] = 2 }, iter:collect_table())
    --     end)
    --
    --     it("searches in the correct order", function()
    --         -- stylua: ignore
    --         local search = { function(_) return true end }
    --
    --         local iter = Iterator:new({ 0, 1, 2, 3, 4 }):reverse():search(search)
    --         assert.are.same({ 4 }, iter:collect_table())
    --     end)
    --
    --     it("searches for duplicate items", function()
    --         -- stylua: ignore
    --         local search = {
    --             function(v) return v > 2 end,
    --             function(v) return v > 3 end,
    --         }
    --
    --         local iter = Iterator:new({ 0, 1, 2, 3, 4 }):reverse():search(search)
    --         assert.are.same({ 4, 4 }, iter:collect_table())
    --     end)
    -- end)
end)
