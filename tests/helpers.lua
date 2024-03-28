local Helpers = {}

Helpers.root_dir = vim.fn.fnamemodify(".", ":p")
Helpers.test_dir = vim.fs.joinpath(Helpers.root_dir, ".tests/")
Helpers.fixture_dir = vim.fs.joinpath(Helpers.root_dir, "tests", "fixtures")

function Helpers.fixture(name)
    local path = vim.fs.joinpath(Helpers.fixture_dir, string.format("%s.json", name))

    local fd = assert(vim.loop.fs_open(path, "r", 438))
    local stat = assert(vim.loop.fs_fstat(fd))
    local str = assert(vim.loop.fs_read(fd, stat.size, 0))
    assert(vim.loop.fs_close(fd))

    ---@cast str string

    return assert(vim.json.decode(str))
end

return Helpers
