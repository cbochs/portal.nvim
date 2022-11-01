local M = {}

--- @enum Portal.Direction
M.Direction = {
	BACKWARD = 0,
	FORWARD = 1,
	NONE = 2,
}

--- @enum Portal.MarkScope
M.MarkScope = {
	--- Marks are ephemeral and are deleted on exit
	NONE = "none",

	--- Use a global namespace for marks
	GLOBAL = "global",

	--- Use the current working directory as the mark namespace
	DIRECTORY = "directory",

	--- Use the reported "root_dir" from LSP clients as the mark namespace
	LSP = "lsp",
}

return M
