local Option = require("portal.option")

describe("option", function()
    it("acts as a Some-type when given a value", function()
        assert.is_true(Option:some("foo"):is_some())
    end)

    it("acts as a None-type when not given a value", function()
        assert.is_true(Option:none():is_none())
    end)

    describe("#unwrap", function()
        it("unwraps a Some-type into a value", function()
            assert.equals(1, Option:some(1):unwrap())
        end)

        it("unwraps a None-type into an error", function()
            local none = Option:none()
            local ok, _ = pcall(Option.unwrap, none)
            assert.is_false(ok)
        end)
    end)

    describe("#unwrap_or", function()
        it("unwraps a Some-type into a value", function()
            assert.equals(1, Option:some(1):unwrap_or(2))
        end)

        it("unwraps a None-type into a default value", function()
            assert.equals(2, Option:none():unwrap_or(2))
        end)
    end)
end)
