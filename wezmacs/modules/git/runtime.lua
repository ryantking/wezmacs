-- Small process boundary shared by local Git queries and direct tool launchers.
local wezterm = require("wezterm")
local M = {}
-- Shared by subprocess queries and argv handed to the terminal renderer.
function M.git_args(bin, args)
	local argv = {
		bin,
		"--no-optional-locks",
		"--no-lazy-fetch",
		"-c",
		"core.fsmonitor=false",
		"-c",
		"diff.autoRefreshIndex=false",
	}
	for _, arg in ipairs(args) do
		argv[#argv + 1] = arg
	end
	return argv
end
function M.run(name, override, args)
	if override ~= nil and (type(override) ~= "string" or override == "" or override:find("\0", 1, true)) then
		return nil, nil, "Executable override must be one nonempty binary path."
	end
	local bins = { override or name }
	if not override then
		if wezterm.target_triple:find("apple", 1, true) then
			bins[#bins + 1] = "/opt/homebrew/bin/" .. name
			bins[#bins + 1] = "/usr/local/bin/" .. name
		end
		bins[#bins + 1] = wezterm.home_dir .. "/.local/bin/" .. name
	end
	for _, bin in ipairs(bins) do
		local argv = { bin }
		if name == "git" then
			argv = M.git_args(bin, args)
		else
			for _, arg in ipairs(args) do
				argv[#argv + 1] = arg
			end
		end
		local ok, success, stdout, stderr = pcall(wezterm.run_child_process, argv)
		if ok then
			if success then
				return stdout, bin
			end
			local context = name == "git" and " (local objects only; lazy fetching disabled)" or ""
			return nil, nil, name .. " failed" .. context .. ": " .. tostring(stderr ~= "" and stderr or stdout)
		end
	end
	return nil, nil, "Cannot start " .. (override or name) .. "; check installation or executable path."
end
-- Presentation only: IDs/argv always preserve the original bytes.
function M.label(value)
	return (tostring(value):gsub("%c", function(c) return string.format("\\x%02x", c:byte()) end))
end
return M
