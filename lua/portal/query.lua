local M = {}

--- @alias Portal.Predicate fun(jump: Portal.Jump): boolean

--- @class Portal.Query
--- @field predicate Portal.Predicate
--- @field type string
--- @field name string
--- @field name_short string

--- @alias Portal.QueryLike string | Portal.Predicate | Portal.Query

--- @type Portal.Query[]
local _queries = {}

setmetatable(M, {
	--- @return Portal.Query
	__index = function(_, index)
		return _queries[index]
	end,
})

--- @param key string
--- @param predicate Portal.Predicate
--- @param opts { name?: string, name_short?: string }
function M.register(key, predicate, opts)
	_queries[key] = {
		predicate = predicate,
		type = key,
		name = opts.name or "",
		name_short = opts.name_short or "",
	}
end

--- @param queries Portal.QueryLike[]
--- @return Portal.Query[]
function M.resolve(queries)
	--- @type Portal.Query[]
	local query = {}

	for _, query_item in pairs(queries) do
		if type(query_item) == "string" then
			table.insert(query, M[query_item])
		elseif type(query_item) == "function" then
			table.insert(query, {
				predicate = query_item,
				type = "",
				name = "",
				name_short = "",
			})
		elseif type(query_item) == "table" then
			table.insert(query, query_item)
		end
	end

	return query
end

--- @param jump Portal.Jump
--- @return boolean
local function is_valid(jump)
	return jump.buffer ~= nil and vim.api.nvim_buf_is_valid(jump.buffer)
end

--- @param jump Portal.Jump
--- @return boolean
local function is_different_buffer(jump)
	return jump.buffer ~= vim.fn.bufnr()
end

--- @param jump Portal.Jump
--- @return boolean
local function is_modified(jump)
	return is_valid(jump) and is_different_buffer(jump) and vim.api.nvim_buf_get_option(jump.buffer, "modified")
end

--- @param jump Portal.Jump
--- @return boolean
local function is_tagged(jump)
	local tag = require("portal.tag")
	return is_valid(jump) and is_different_buffer(jump) and tag.exists(jump.buffer)
end

M.register("valid", is_valid, { name = "Jump", name_short = "J" })
M.register("different", is_different_buffer, { name = "Different", name_short = "D" })
M.register("modified", is_modified, { name = "Modified", name_short = "+" })
M.register("tagged", is_tagged, { name = "Tagged", name_short = "T" })

return M
