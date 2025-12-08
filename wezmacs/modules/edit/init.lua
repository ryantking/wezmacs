--[[
  Module: edit
  Description: Editor and file management integrations
]]

local wezterm = require("wezterm")
local act = wezterm.action
local wezmacs = require("wezmacs")

return {
	name = "edit",
	description = "Editor and file management integrations",

	deps = { "broot", "yazi", "vim", "code" },

	opts = {
		editor = "vim",
		ide = "code",
		file_searcher = "br",
		file_manager = "yazi",
	},

	keys = function(opts)
		return {
			{
				key = "Space",
				mods = "LEADER",
				action = wezmacs.action.SmartSplit(opts.file_searcher),
				desc = "find-file",
			},
			{
				key = "Enter",
				mods = "LEADER",
				action = wezmacs.action.SmartSplit(opts.editor),
				desc = "open-editor",
			},
			{
				key = ".",
				mods = "LEADER",
				action = wezmacs.action.SmartSplit(opts.file_manager),
				desc = "browse-files",
			},
			{
				key = "i",
				mods = "LEADER",
				action = wezterm.action_callback(function(_, pane)
					local cwd_uri = pane:get_current_working_dir()
					local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
					wezterm.background_child_process({ opts.ide, cwd })
				end),
				desc = "open-ide",
			},
		}
	end,
}
