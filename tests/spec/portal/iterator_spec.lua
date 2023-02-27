local Iterator = require("portal.iterator")

describe("iterator", function()
    it("handles an empty list", function()
        assert.is_nil(Iterator:new():next())
    end)

    it("can be iterated", function()
        local iter = Iterator:new({ "a", "b", "c" })
        assert.are.same({ 1, "a" }, { iter:next(0) })
        assert.are.same({ 2, "b" }, { iter:next(1) })
        assert.are.same({ 3, "c" }, { iter:next(2) })
    end)

    it("can be iterated in steps", function()
        local iter = Iterator:new({ "a", "b", "c", "d" }):step_by(2)
        assert.are.same({ "b", "d" }, iter:collect())
    end)

    it("can be iterated in reverse", function()
        local iter = Iterator:new({ "a", "b", "c" }):reverse()
        assert.are.same({ "c", "b", "a" }, iter:collect())
    end)

    it("can start at an arbitraty index", function()
        local iter = Iterator:new({ 1, 2, 3, 4, 5, 6 }):start_at(5)
        assert.are.same({ 5, 6 }, iter:collect())
    end)

    it("can be exhausted", function()
        assert.are.same({ "a", "b", "c" }, Iterator:new({ "a", "b", "c" }):collect())
    end)

    describe("#filter", function()
        it("filters and iterator", function()
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
        it("transforms the values", function()
            -- stylua: ignore
            local map = function(v) return v * 2 end
            local iter = Iterator:new({ 0, 1, 2 }):map(map)
            assert.are.same({ 0, 2, 4 }, iter:collect())
        end)
    end)

    describe("#search", function()
        it("searches for specific values", function()
            -- stylua: ignore
            local search = {
                { call = function(v) return v == 4 end },
                { call = function(v) return v == 2 end },
                { call = function(v) return v == 5 end },
            }
            -- stylua: ignore
            local map = function(v) return v.value end

            local iter = Iterator:new({ 0, 1, 2, 3, 4 }):search(search):map(map)
            assert.are.same({ 2, 4 }, iter:collect())
        end)
    end)
end)
