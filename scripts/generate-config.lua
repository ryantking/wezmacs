#!/usr/bin/env lua
-- Generate modules.lua and config.lua without loading WezTerm or module specs.
-- Usage: lua scripts/generate-config.lua [output_directory]
-- Default: WEZMACSDIR > XDG_CONFIG_HOME/wezmacs > HOME/.config/wezmacs.
-- Run the script in its checkout; discovery uses ../wezmacs/modules/ relative
-- to the script, not the working directory. Requires Lua and a POSIX shell.

local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end

local function getenv(name)
	local value = os.getenv(name)
	return value ~= "" and value or nil
end

local function get_config_dir()
	local wezmacs_dir = getenv("WEZMACSDIR")
	if wezmacs_dir then
		return wezmacs_dir
	end
	local xdg_config = getenv("XDG_CONFIG_HOME")
	if xdg_config then
		return xdg_config .. "/wezmacs"
	end
	return assert(getenv("HOME"), "Set HOME, XDG_CONFIG_HOME, WEZMACSDIR, or an output directory") .. "/.config/wezmacs"
end

local function scan_modules()
	local script_dir = arg[0]:match("^(.*)/[^/]+$") or "."
	local modules_dir = script_dir .. "/../wezmacs/modules"
	local command = "for path in "
		.. quote(modules_dir)
		.. "/*/init.lua; do "
		.. 'if [ -f "$path" ]; then printf \'%s\\0\' "$path"; fi; done'
	local handle = assert(io.popen(command))
	local paths = assert(handle:read("*a"))
	assert(handle:close(), "Failed to list modules: " .. modules_dir)

	local modules = {}
	for path in paths:gmatch("([^%z]+)%z") do
		table.insert(modules, assert(path:match("([^/]+)/init%.lua$")))
	end
	assert(#modules > 0, "No modules found in: " .. modules_dir)
	table.sort(modules)
	return modules
end

local function generate_modules(modules)
	local lines = {
		"-- Modules found in this checkout's wezmacs/modules/*/init.lua.",
		"-- Remove entries to disable modules. A string uses the module's defaults.",
		'-- Customize options with { "term", opts = { scrollback_lines = 10000 } }.',
		"-- See each module's init.lua for its supported options.",
		"return {",
	}
	for _, name in ipairs(modules) do
		table.insert(lines, string.format("\t%q,", name))
	end
	table.insert(lines, "}\n")
	return table.concat(lines, "\n")
end

local config_template = [[-- Global overrides; omitted settings retain wezmacs/config.lua defaults.
-- Module-specific options belong in modules.lua.
return {
	-- color_scheme = "Rose Pine",
	-- term_mod = "CTRL|SHIFT",
	-- gui_mod = "SUPER",
	-- ctrl_mod = "CTRL",
	-- alt_mod = "ALT",
	-- shell = "/bin/bash",
}
]]

local function main()
	local output_dir = arg[1] or get_config_dir()
	assert(output_dir ~= "", "The output directory must not be empty")
	if output_dir:sub(1, 1) ~= "/" then
		output_dir = "./" .. output_dir
	end

	-- Refuse the whole pair if either path exists, including a dangling link.
	for _, name in ipairs({ "config.lua", "modules.lua" }) do
		local path = output_dir .. "/" .. name
		if os.execute("test -e " .. quote(path) .. " || test -L " .. quote(path)) then
			error("Refusing to overwrite existing path: " .. path)
		end
	end

	local modules = scan_modules()
	assert(os.execute("mkdir -p " .. quote(output_dir)), "Failed to create output directory: " .. output_dir)
	for _, entry in ipairs({ { "modules.lua", generate_modules(modules) }, { "config.lua", config_template } }) do
		local path = output_dir .. "/" .. entry[1]
		-- POSIX noclobber also protects files created after the preflight check.
		local file = assert(io.popen("set -C; cat > " .. quote(path), "w"))
		local written, write_err = file:write(entry[2])
		local closed = file:close()
		assert(written and closed, "Failed to write " .. path .. (write_err and ": " .. write_err or ""))
		print("Generated " .. path)
	end
	print("Edit modules.lua to select modules and config.lua to override global settings.")
end

main()
