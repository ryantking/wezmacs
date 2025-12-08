--[[
  Module: agent
  Description: Manage AI coding agents
]]

local wezterm = require("wezterm")
local act = require("actions")
local wezmacs = require("wezmacs")

return {
	name = "agent",
	description = "Manage AI coding agents",

	deps = { "agent", "cursor", "agentctl" },

	opts = {
		agent = "claude",
		alt_agent = "agent",
	},

	keys = function(opts)
		return {
			{ key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\x1b\r"), desc = "newline" },
			LEADER = {
				a = {
					{ key = "a", action = wezmacs.action.SmartSplit(opts.agent), desc = "split" },
					{ key = "A", action = wezmacs.action.NewTab(opts.agent), desc = "tab" },
					{ key = "c", action = wezmacs.action.SmartSplit(opts.alt_agent), desc = "alt-agent/split" },
					{ key = "C", action = wezmacs.action.NewTab(opts.alt_agent), desc = "alt-agent/tab" },
					{ key = "Enter", action = act.CreateWorkspace(opts.agent), desc = "create-workspace" },
					{ key = "Space", action = act.OpenWorkspace(opts.agent), desc = "open-workspaces" },
					{ key = "x", action = act.DeleteWorkspace, desc = "delete-workspace" },
				},
			},
		}
	end,
}
