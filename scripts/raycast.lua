-- Headless read-only bridge. Requests are data, never code or process commands.
local wezterm = require("wezterm")
local ok, config_or_error = pcall(function()
	local root = assert(os.getenv("WEZMACS_RAYCAST_ROOT"), "Missing Raycast root.")
	package.path = root .. "/?.lua;" .. root .. "/?/init.lua"
	wezterm.background_child_process = function() error("Launches disabled in headless bridge.") end
	local request = wezterm.json_parse(assert(os.getenv("WEZMACS_RAYCAST_REQUEST"), "Missing Raycast request."))
	local data
	if request.op == "hosts" then
		local choices, meta = require("wezmacs.modules.mux.hosts").get_choices()
		data = { choices = choices, meta = meta }
	elseif request.op == "ssh-plan" then
		local argv, err = require("wezmacs.modules.mux.hosts").launch_args(request.selection)
		assert(argv, err)
		data = { argv = argv }
	elseif request.op == "workspaces" then
		local names = request.workspaces
		assert(type(names) == "table", "Invalid workspace inventory.")
		for index, name in pairs(names) do
			assert(
				type(index) == "number"
					and index >= 1
					and index <= #names
					and index % 1 == 0
					and type(name) == "string"
					and #name > 0
					and #name <= 4096
					and not name:find("%c"),
				"Invalid workspace inventory."
			)
		end
		data = { choices = require("wezmacs.modules.mux.workspaces").get_choices(nil, names) }
	else
		error("Unknown Raycast operation.")
	end
	local config = wezterm.config_builder()
	---@cast config WezmacsConfigBuilder
	config:set_strict_mode(true)
	config.keys = { { key = "F24", mods = "NONE", action = wezterm.action.SendString("WEZMACS_RAYCAST_OK") } }
	local encoded = wezterm.json_encode({ ok = true, data = data })
	-- Native json_encode maps empty Lua tables to objects; choices is always an array.
	if data.choices and #data.choices == 0 then
		encoded = encoded:gsub('"choices":{}', '"choices":[]', 1)
	end
	io.stderr:write("WEZMACS_RAYCAST_RESULT " .. encoded .. "\n")
	return config
end)
if not ok then
	io.stderr:write(
		"WEZMACS_RAYCAST_RESULT " .. wezterm.json_encode({ ok = false, error = tostring(config_or_error) }) .. "\n"
	)
	os.exit(1)
end
return config_or_error
