vim.api.nvim_create_user_command("Debug", function()
	-- Unload all packages
	for name, _ in pairs(package.loaded) do
		if name:match("^portal") then
			package.loaded[name] = nil
		end
	end
end, {})
