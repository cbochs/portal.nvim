local H = require("tests.helpers")
local Jumplist = require("portal.builtin.jumplist")
local Query = require("portal.query")

local function test_generate(name)
    local fixture = H.fixture(name)

    describe(name, function()
        before_each(function()
            vim.fn.getjumplist = function()
                return vim.deepcopy(fixture.jumplist)
            end
            vim.api.nvim_buf_is_valid = function()
                return true
            end
        end)

        it("next", function()
            local query = Query.new(Jumplist.generate):prepare({ reverse = false })
            local results = query:search():totable()
            assert.are.same(fixture.next, results)
        end)

        it("prev", function()
            local query = Query.new(Jumplist.generate):prepare({ reverse = true })
            local results = query:search():totable()
            assert.are.same(fixture.prev, results)
        end)
    end)
end

describe("jumplist", function()
    describe("#generate", function()
        test_generate("jumplist_empty")
        test_generate("jumplist_end")
        test_generate("jumplist_middle")
        test_generate("jumplist_start")
    end)
    describe("#transform", function() end)
end)
