stds.nvim = {
    read_globals = { "jit" },
}

std = "lua51+nvim"

-- Don't report unused self arguments of methods.
self = false

-- Rerun tests only if their modification time changed.
cache = true

-- Global objects defined by the C code
read_globals = {
    "vim",
}

globals = {
    "vim.g",
    "vim.b",
    "vim.w",
    "vim.o",
    "vim.bo",
    "vim.wo",
    "vim.go",
    "vim.env",
}
