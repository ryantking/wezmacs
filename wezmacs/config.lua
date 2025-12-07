--[[
  WezMacs Configuration Management
  
  Provides default global settings and a function to load user configuration.
]]

local wezterm = require("wezterm")

local M = {}

-- Default global configuration
M.defaults = {
  font_size = 12.0,
  font_family = nil,  -- nil = use WezTerm default
  color_scheme = nil,  -- nil = use WezTerm default
  mod_key = "CMD",
  leader_key = "Space",
  leader_mod = "CTRL",
  shell = os.getenv("SHELL") or "/bin/bash",  -- User's shell
  -- Add more defaults as needed
}

-- Load user configuration from a file path
-- Merges user config with defaults
function M.load(user_config_path)
  local config = {}
  
  -- Start with defaults
  for k, v in pairs(M.defaults) do
    config[k] = v
  end
  
  -- Try to load user config file
  if user_config_path then
    local file = io.open(user_config_path, "r")
    if file then
      file:close()
      
      local chunk, err = loadfile(user_config_path)
      if chunk then
        local success, user_config = pcall(chunk)
        if success and user_config and type(user_config) == "table" then
          -- Merge user config into defaults
          for k, v in pairs(user_config) do
            config[k] = v
          end
        end
      end
    end
  end
  
  return config
end

return M
