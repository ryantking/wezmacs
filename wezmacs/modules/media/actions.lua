--[[
  Media module actions
  All action callbacks and helper functions for media module
]]

local action_lib = require("wezmacs.lib.actions")

local M = {}

M.launch_spotify_player = action_lib.new_tab_action({ "spotify_player" })

return M
